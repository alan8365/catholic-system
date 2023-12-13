# frozen_string_literal: true

module Api
  class ParishionersController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[picture]
    before_action :find_parishioner, except: %i[create index id_card_pdf letterhead]
    before_action :find_baptism, only: %i[id_card certificate]
    before_action :find_eucharist, only: %i[certificate]
    before_action :find_confirmation, only: %i[certificate]

    include ActionController::MimeResponds

    # GET /parishioners
    def index
      authorize! :read, Parishioner
      query = params[:any_field]
      name_query = params[:name]
      is_archive = params[:is_archive]

      page = params[:page] || '1'
      per_page = params[:per_page] || '10'

      page = page.to_i
      per_page = per_page.to_i

      if query.present? || name_query.present?
        string_filed = if query.present?
                         %w[
                           (last_name||first_name) home_number gender
                           home_phone mobile_phone
                         ]
                       elsif name_query
                         %w[
                           (last_name||first_name)
                         ]
                       end

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = if query.present?
                        string_filed.map { |_| "%#{query}%" }.compact
                      elsif name_query
                        string_filed.map { |_| "%#{name_query}%" }.compact
                      end

        @parishioners = Parishioner.where([query_string, *query_array])
      else
        @parishioners = Parishioner.all
      end

      @parishioners = if is_archive == 'true'
                        @parishioners.where('move_out_date is not null')
                      else
                        @parishioners.where('move_out_date is null')
                      end

      @parishioners = @parishioners.select(*%w[
                                             id
                                             first_name last_name gender birth_at postal_code address home_number
                                             father mother father_id mother_id
                                             home_phone mobile_phone nationality
                                             profession company_name comment
                                             move_in_date original_parish
                                             move_out_date move_out_reason destination_parish
                                           ])

      render json: @parishioners.paginate(page:, per_page:),
             include: {
               mother_instance: {},
               father_instance: {},
               baptism: { methods: [:serial_number] },
               confirmation: { methods: [:serial_number] },
               eucharist: { methods: [:serial_number] },
               wife: {},
               husband: {}
             },
             methods: %i[children sibling],
             status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner

      render json: @parishioner,
             include: {
               mother_instance: {},
               father_instance: {},
               baptism: { methods: [:serial_number] },
               confirmation: { methods: [:serial_number] },
               eucharist: { methods: [:serial_number] },
               wife: {},
               husband: {}
             },
             methods: %i[children sibling],
             status: :ok
    end

    def picture
      if @parishioner.picture.attached?
        send_file @parishioner.picture_url, type: 'image/png', disposition: 'inline'
      else
        head :not_found
      end
    end

    # POST /parishioners
    def create
      authorize! :create, Parishioner

      create_params = parishioner_params.to_h

      begin
        # Picture extension check
        allow_extensions = %w[image/jpeg image/png]
        create_params = params_picture_check(create_params, allow_extensions)
      rescue ArgumentError
        return render json: { errors: I18n.t('parishioner.picture_extension_error') % allow_extensions.to_s },
                      status: :unprocessable_entity
      end

      @parishioner = Parishioner.new(create_params)
      if @parishioner.save
        render json: @parishioner, status: :created
      else
        render json: { errors: @parishioner.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /parishioners/{id}
    def update
      authorize! :update, @parishioner

      update_params = parishioner_params.to_h

      begin
        # Picture extension check
        allow_extensions = %w[image/jpeg image/png]
        update_params = params_picture_check(update_params, allow_extensions)
      rescue ArgumentError
        return render json: { errors: I18n.t('parishioner.picture_extension_error') % allow_extensions.to_s },
                      status: :unprocessable_entity
      end

      if update_params.include?('father_id') && !update_params['father_id'].empty?
        father_id = update_params['father_id']
        father = Parishioner.find_by_id(father_id)

        if father.nil?
          return render json: {
                          errors: I18n.t('activerecord.errors.models.parishioners.attributes.father_id.not_found')
                        },
                        status: :unprocessable_entity
        end

        @parishioner.father_instance = father
        @parishioner.father = father.full_name if father

        update_params.delete('father_id')
        update_params.delete('father')
      end

      if update_params.include?('mother_id') && !update_params['mother_id'].empty?
        mother_id = update_params['mother_id']
        mother = Parishioner.find_by_id(mother_id)

        if mother.nil?
          return render json: {
                          errors: I18n.t('activerecord.errors.models.parishioners.attributes.mother_id.not_found')
                        },
                        status: :unprocessable_entity
        end

        @parishioner.mother_instance = mother
        @parishioner.mother = mother.full_name if mother

        update_params.delete('mother_id')
        update_params.delete('mother')
      end

      # Head of household change home number clear original head of household
      if update_params.include?('home_number') && !update_params['home_number'].empty?
        home_number = @parishioner.home_number
        household = Household.find_by_home_number(home_number)

        household.head_of_household = nil if household.head_of_household&.id == @parishioner.id
        household.save
      end

      return if @parishioner.update(update_params)

      render json: { errors: @parishioner.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /parishioners/{id}
    def destroy
      authorize! :destroy, @parishioner

      @parishioner.destroy
    end

    def id_card
      authorize! :read, @parishioner

      canvas = get_id_card_canvas(@parishioner)

      file_path = Rails.root.join('tmp', 'cards', "#{@parishioner.id}.png")

      canvas.write(file_path)

      send_file file_path, type: 'image/png', disposition: 'inline'
    end

    def id_card_back
      authorize! :read, @parishioner

      font_path = Rails.root.join('asset', 'DFKai-SB.ttf').to_s

      # Card b-side
      canvas_back = get_id_card_back_canvas(font_path)

      back_file_path = Rails.root.join('tmp', 'cards', 'card_back.png').to_s

      canvas_back.write(back_file_path)

      send_file back_file_path, type: 'image/png', disposition: 'inline'
    end

    # FIXME: change the page size from letter to A4
    def id_card_pdf
      authorize! :read, Parishioner

      require 'prawn'
      require 'prawn/measurement_extensions'

      parishioner_ids = params[:ids]

      all_baptisms = if parishioner_ids.present?
                       Baptism.where(parishioner_id: parishioner_ids)
                     else
                       Baptism
                         .joins(:parishioner)
                         .where('parishioners.move_out_date is null')
                     end

      if all_baptisms.empty?
        render json: { errors: I18n.t('baptism_not_found') }, status: :not_found
      elsif parishioner_ids.present? && all_baptisms.count != parishioner_ids.count
        missing_parishioner_ids = parishioner_ids - all_baptisms.pluck(:parishioner_id).uniq
        missing_parishioner_names = Parishioner.where(id: missing_parishioner_ids).map(&:full_name)

        render json: { errors: format(I18n.t('parishioners_id_s_not_found_in_baptism'), missing_parishioner_names.to_s) },
               status: :not_found
      else
        save_path = Rails.root.join('tmp', 'id_cards.pdf')
        im_back_path = Rails.root.join('tmp', 'cards', 'card_back.png').to_s

        font_path = Rails.root.join('asset', 'DFKai-SB.ttf').to_s

        # Card back file check
        canvas_back = get_id_card_back_canvas(font_path)
        canvas_back.write(im_back_path)

        # Card file check
        all_baptisms.each do |baptism|
          im_path = Rails.root.join('tmp', 'cards', "#{baptism.parishioner.id}.png").to_s
          canvas = get_id_card_canvas(baptism.parishioner)
          canvas.write(im_path)
        end

        width = 90.mm
        height = 54.mm
        put_stroke = true
        Prawn::Document.generate(save_path) do
          row_limit = 4

          all_baptisms.each_with_index do |baptism, index|
            start_new_page if (index % row_limit).zero? && (index != 0)

            im_path = Rails.root.join('tmp', 'cards', "#{baptism.parishioner.id}.png").to_s

            y_position = cursor
            bounding_box([0, y_position], width: 92.mm, height: 56.mm) do
              if put_stroke
                transparent(0.5) do
                  dash(1)
                  stroke_bounds
                  undash
                end
              end

              move_down 1.mm
              image im_path, width:, height:, position: :center
            end

            bounding_box([92.mm, y_position], width: 92.mm, height: 56.mm) do
              if put_stroke
                transparent(0.5) do
                  dash(1)
                  stroke_bounds
                  undash
                end
              end

              move_down 1.mm
              image im_back_path, width:, height:, position: :center
            end
          end
        end

        send_file save_path, type: 'application/pdf', disposition: 'attachment; filename=id_cards.pdf'
      end
    end

    def certificate
      authorize! :read, @parishioner

      filename = "#{@parishioner.full_name}-領洗堅振證明書.docx"

      doc = DocxReplace::Doc.new("#{Rails.root}/asset/領洗堅振證明書.docx", "#{Rails.root}/tmp")

      # Personal info
      doc.replace('$LN$', @parishioner.last_name)
      doc.replace('$FN$', @parishioner.first_name)
      doc.replace('$CN$', @baptism.christian_name)

      doc.replace('$FaN$', @parishioner.father_name)
      doc.replace('$MoN$', @parishioner.mother_name)

      birth_at = @parishioner.birth_at
      doc.replace('$BirD$', birth_at.day)
      doc.replace('$BirM$', birth_at.month)
      doc.replace('$BirY$', birth_at.year)

      doc.replace('$Addr$', @parishioner.address)
      doc.replace('$Tel$', @parishioner.mobile_phone)

      # Baptism info
      baptized_at = @baptism.baptized_at
      doc.replace('$BapD$', baptized_at.day)
      doc.replace('$BapM$', baptized_at.month)
      doc.replace('$BapY$', baptized_at.year)

      doc.replace('$BapCh$', @baptism.baptized_location)
      doc.replace('$BapNum$', @baptism.serial_number)

      doc.replace('$BapPre$', @baptism.presbyter)
      doc.replace('$BapGP$', @baptism.godparent)

      # Eucharist info
      eucharist_at = @eucharist.eucharist_at
      doc.replace('$EucD$', eucharist_at.day)
      doc.replace('$EucM$', eucharist_at.month)
      doc.replace('$EucY$', eucharist_at.year)

      doc.replace('$EucCh$', @eucharist.eucharist_location)
      doc.replace('$EucNum$', @eucharist.serial_number)

      doc.replace('$EucPre$', @eucharist.presbyter)

      # Confirmation info
      confirmed_at = @confirmation.confirmed_at
      doc.replace('$ConD$', confirmed_at.day)
      doc.replace('$ConM$', confirmed_at.month)
      doc.replace('$ConY$', confirmed_at.year)

      doc.replace('$ConCh$', @confirmation.confirmed_location)
      doc.replace('$ConNum$', @confirmation.serial_number)

      doc.replace('$ConPre$', @confirmation.presbyter)
      doc.replace('$ConGP$', @confirmation.godparent)

      # Marriage info
      married = @parishioner.married?
      married_text = if married
                       '□Yes ■No'
                     else
                       '■Yes □No'
                     end

      doc.replace('$IsMarry$', married_text)

      # Date today
      today = Date.today
      doc.replace('$ThisD$', today.day)
      doc.replace('$ThisM$', today.month)
      doc.replace('$ThisY$', today.year)

      # Save file
      tmp_file = Tempfile.new('word_template', "#{Rails.root}/tmp")
      doc.commit(tmp_file.path)

      send_file tmp_file.path, type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                               disposition: 'attachment',
                               filename:
    end

    def get_id_card_back_canvas(font_path)
      canvas_back = Magick::ImageList.new
      canvas_back.new_image(368, 224)
      background_back = canvas_back[0]

      # Draw church
      church_path = Rails.root.join('asset', '天主堂水彩畫.png').to_s
      church = Magick::Image.read(church_path).first
      church.resize_to_fit!(303, 224)

      background_back.composite!(church, Magick::CenterGravity, 0, 0, Magick::OverCompositeOp)

      # Draw info
      info_text1 = '電話：04-7222744'
      info_text2 = '地址：彰化市民生路20-1號'

      info_draw = Magick::Draw.new
      info_draw.font = font_path
      info_draw.pointsize = 18
      info_draw.gravity = Magick::SouthWestGravity
      info_draw.fill = '#000000'

      info_offset_x = 20
      info_offset_y = 10
      info_draw.annotate(canvas_back, 0, 0, info_offset_x, info_offset_y + 20, info_text1)
      info_draw.annotate(canvas_back, 0, 0, info_offset_x, info_offset_y, info_text2)
      canvas_back
    end

    def get_id_card_canvas(parishioner)
      font_path = Rails.root.join('asset', 'DFKai-SB.ttf').to_s

      canvas = Magick::ImageList.new
      canvas.new_image(368, 224)
      background = canvas[0]

      # Draw mark
      mark_path = Rails.root.join('asset', '堂徽.png').to_s
      mark = Magick::Image.read(mark_path).first
      mark.resize_to_fit!(60, 60)

      background.composite!(mark, Magick::NorthWestGravity, 5, 10, Magick::OverCompositeOp)

      # Draw avatar
      size = 160
      picture_url = parishioner.picture_url
      if !picture_url.empty? && File.exist?(picture_url)
        avatar = Magick::Image.read(picture_url).first
        avatar.resize_to_fit!(size, size)

        background.composite!(avatar, Magick::SouthEastGravity, 0, 0, Magick::OverCompositeOp)
      end

      # Draw title
      title_text1 = '天主教台中教區彰化聖十字架天主堂'
      title_text2 = '教 友 證'

      title_draw = get_text_draw(font_path, gravity: Magick::NorthGravity)

      title_offset_x = 30
      title_offset_y = 10
      title_draw.annotate(canvas, 0, 0, title_offset_x, title_offset_y, title_text1)
      title_draw.annotate(canvas, 0, 0, title_offset_x - 10, title_offset_y + 30, title_text2)

      # Draw serial number
      serial_number_text = "NO.#{parishioner.baptism.serial_number}"

      serial_number_draw = get_text_draw(font_path)

      serial_number_offset_x = 30
      serial_number_offset_y = 70
      serial_number_draw.annotate(canvas, 0, 0, serial_number_offset_x, serial_number_offset_y, serial_number_text)

      # Draw name and christian name
      name_text = "#{parishioner.full_name}/#{parishioner.baptism.christian_name}"

      name_draw = get_text_draw(font_path, point_size: 22)

      name_offset_x = 30
      name_offset_y = 90
      name_draw.annotate(canvas, 0, 0, name_offset_x, name_offset_y, name_text)

      # Draw date field
      date_field_text = '領洗日期'
      godparent_field_text = '代父母'
      presbyter_field_text = '付洗司鐸'

      field_draw = get_text_draw(font_path)
      field_draw.text_align(Magick::LeftAlign)

      field_offset_x = 10
      field_offset_y = 155
      field_offset_y_diff = 20

      field_draw.text(field_offset_x, field_offset_y, date_field_text)
      field_draw.text(field_offset_x, field_offset_y + field_offset_y_diff, godparent_field_text)
      field_draw.text(field_offset_x, field_offset_y + field_offset_y_diff * 2, presbyter_field_text)

      field_draw.draw(canvas)

      # Draw date
      date_text = parishioner.baptism.baptized_at.strftime('%Y/%m/%d').to_s
      godparent_text = parishioner.baptism.godparent.to_s
      presbyter_text = parishioner.baptism.presbyter.to_s

      baptism_draw = get_text_draw(font_path)
      baptism_draw.text_align(Magick::RightAlign)

      baptism_offset_x = 185
      baptism_draw.text(baptism_offset_x, field_offset_y, date_text)
      baptism_draw.text(baptism_offset_x, field_offset_y + field_offset_y_diff, godparent_text)
      baptism_draw.text(baptism_offset_x, field_offset_y + field_offset_y_diff * 2, presbyter_text)

      baptism_draw.draw(canvas)
      canvas
    end

    def letterhead
      authorize! :read, Parishioner

      parishioner_ids = params[:ids]

      parishioners = if parishioner_ids.present?
                       Parishioner.where(id: parishioner_ids)
                     else
                       Parishioner.where('move_out_date is null')
                     end

      require 'prawn'
      require 'prawn/measurement_extensions'

      filename = '教友信籤.pdf'

      save_path = Rails.root.join('tmp', filename)

      width = 70.mm
      height = 37.mm
      put_stroke = false
      Prawn::Document.generate(save_path, page_size: 'A4', margin: 0) do
        page_top = cursor

        parishioners.each_with_index do |parishioner, index|
          y_position = page_top - (height * (index / 3))
          x_position = width * (index % 3)

          margin_top = 0.4.in
          margin_left = 0.3.in
          bounding_box(
            [x_position + margin_left, y_position - margin_top],
            width: width - margin_left,
            height: height - margin_top
          ) do
            stroke_bounds if put_stroke

            name = parishioner.full_name
            postal_code = parishioner.postal_code
            address_prefix, address_postfix = parishioner.address_divided
            home_number = parishioner.home_number

            font(Rails.root.join('asset', 'MingLiU.ttf'), size: 12) do
              text "#{name} 兄弟/姊妹 收"
              text " #{postal_code} #{address_prefix}"
              text address_postfix.to_s
              text "家號#{home_number}", align: :center
            end
          end
        end
      end

      send_file save_path, type: 'application/pdf', disposition: "attachment; filename=#{filename}.pdf"
    end

    private

    def get_text_draw(font_path, point_size: 18, gravity: Magick::NorthWestGravity)
      title_draw = Magick::Draw.new
      title_draw.font = font_path
      title_draw.pointsize = point_size
      title_draw.gravity = gravity
      title_draw.fill = '#000000'
      title_draw
    end

    def find_parishioner
      @parishioner = Parishioner.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('parishioner_not_found') }, status: :not_found
    end

    def find_baptism
      @baptism = Baptism.find_by_parishioner_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('baptism_not_found') }, status: :not_found
    end

    def find_eucharist
      @eucharist = Eucharist.find_by_parishioner_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('eucharist_not_found') }, status: :not_found
    end

    def find_confirmation
      @confirmation = Confirmation.find_by_parishioner_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('confirmation_not_found') }, status: :not_found
    end

    def parishioner_params
      params.permit(%i[
                      first_name last_name gender birth_at postal_code address home_number
                      father mother father_id mother_id
                      home_phone mobile_phone nationality
                      profession company_name comment
                      move_in_date original_parish
                      move_out_date move_out_reason destination_parish
                      picture
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end

    def params_picture_check(create_params, allow_extensions)
      # Picture empty check
      return create_params unless 'picture'.in?(create_params.keys)

      # Picture exist check
      return create_params.except('picture') if create_params['picture'].blank?

      # if create_params['picture'].content_type != 'image/png'
      raise ArgumentError if create_params['picture'].content_type !~ /#{allow_extensions.join('|')}/

      create_params
    end
  end
end
