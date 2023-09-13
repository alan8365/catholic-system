# frozen_string_literal: true

module Api
  class ParishionersController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[picture]
    before_action :find_parishioner, except: %i[create index]
    before_action :find_baptism, only: %i[id_card]

    # GET /parishioners
    def index
      authorize! :read, Parishioner
      query = params[:any_field]
      is_archive = params[:is_archive]

      if query
        string_filed = %w[
          name home_number gender
          home_phone mobile_phone
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

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
                                             name gender birth_at postal_code address home_number
                                             father mother father_id mother_id
                                             home_phone mobile_phone nationality
                                             profession company_name comment
                                             move_in_date original_parish
                                             move_out_date move_out_reason destination_parish
                                           ])

      render json: @parishioners,
             include: %i[
               mother_instance father_instance
               baptism confirmation eucharist
               wife husband
             ],
             methods: %i[children sibling],
             status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner

      render json: @parishioner,
             include: %i[
               mother_instance father_instance
               baptism confirmation eucharist
               wife husband
             ],
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
      create_params.delete('picture') if 'picture'.in?(create_params.keys) && (create_params['picture'].is_a? String)

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
      update_params.delete('picture') if 'picture'.in?(update_params.keys) && (update_params['picture'].is_a? String)

      if update_params.include?('father_id') && !update_params['father_id'].empty?
        father_id = update_params['father_id']
        father = Parishioner.find_by_id(father_id)

        @parishioner.father_instance = father
        @parishioner.father = father.name if father

        update_params.delete('father_id')
        update_params.delete('father')
      end

      if update_params.include?('mother_id') && !update_params['mother_id'].empty?
        mother = Parishioner.find_by_id(update_params['mother_id'])

        @parishioner.mother_instance = mother
        @parishioner.mother = mother.name if mother

        update_params.delete('mother_id')
        update_params.delete('mother')
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

      font_path = '/Users/lucyxu/RubymineProjects/catholic/DFKai-SB.ttf'

      canvas = Magick::ImageList.new
      canvas.new_image(368, 224)
      background = canvas[0]

      # Draw mark
      mark = Magick::Image.read('/Users/lucyxu/RubymineProjects/catholic/asset/堂徽.png').first
      mark.resize_to_fit!(60, 60)

      background.composite!(mark, Magick::NorthWestGravity, 5, 10, Magick::OverCompositeOp)

      # Draw avatar
      size = 160
      avatar = Magick::Image.read(@parishioner.picture_url).first
      avatar.resize_to_fit!(size, size)

      background.composite!(avatar, Magick::SouthEastGravity, 0, 0, Magick::OverCompositeOp)

      # Draw title
      title_text1 = '天主教台中教區彰化聖十字架天主堂'
      title_text2 = '教 友 證'

      title_draw = Magick::Draw.new
      title_draw.font = font_path
      title_draw.pointsize = 18
      title_draw.gravity = Magick::NorthGravity
      title_draw.fill = '#000000'

      title_offset_x = 30
      title_offset_y = 10
      title_draw.annotate(canvas, 0, 0, title_offset_x, title_offset_y, title_text1)
      title_draw.annotate(canvas, 0, 0, title_offset_x - 10, title_offset_y + 30, title_text2)

      # Draw serial number
      serial_number_text = "NO.#{@parishioner.baptism.serial_number}"

      serial_number_draw = Magick::Draw.new
      serial_number_draw.font = font_path
      serial_number_draw.pointsize = 18
      serial_number_draw.gravity = Magick::NorthWestGravity
      serial_number_draw.fill = '#000000'

      serial_number_offset_x = 30
      serial_number_offset_y = 70
      serial_number_draw.annotate(canvas, 0, 0, serial_number_offset_x, serial_number_offset_y, serial_number_text)

      # Draw name and christian name
      name_text = "#{@parishioner.name}/#{@parishioner.baptism.christian_name}"

      name_draw = Magick::Draw.new
      name_draw.font = font_path
      name_draw.pointsize = 22
      name_draw.gravity = Magick::NorthWestGravity
      name_draw.fill = '#000000'

      name_offset_x = 30
      name_offset_y = 90
      name_draw.annotate(canvas, 0, 0, name_offset_x, name_offset_y, name_text)

      # Draw date field
      date_field_text = '領洗日期'
      godparent_field_text = '代父母'
      presbyter_field_text = '付洗司鐸'

      field_draw = Magick::Draw.new
      field_draw.font = font_path
      field_draw.pointsize = 18
      field_draw.gravity = Magick::NorthWestGravity
      field_draw.fill = '#000000'
      field_draw.text_align(Magick::LeftAlign)

      field_offset_x = 10
      field_offset_y = 155
      field_offset_y_diff = 20

      field_draw.text(field_offset_x, field_offset_y, date_field_text)
      field_draw.text(field_offset_x, field_offset_y + field_offset_y_diff, godparent_field_text)
      field_draw.text(field_offset_x, field_offset_y + field_offset_y_diff * 2, presbyter_field_text)

      field_draw.draw(canvas)

      # Draw date
      date_text = @parishioner.baptism.baptized_at.strftime('%Y/%m/%d').to_s
      godparent_text = @parishioner.baptism.godparent.to_s
      presbyter_text = @parishioner.baptism.presbyter.to_s

      baptism_draw = Magick::Draw.new
      baptism_draw.font = font_path
      baptism_draw.pointsize = 18
      baptism_draw.gravity = Magick::NorthWestGravity
      baptism_draw.fill = '#000000'
      baptism_draw.text_align(Magick::RightAlign)

      baptism_offset_x = 185
      baptism_draw.text(baptism_offset_x, field_offset_y, date_text)
      baptism_draw.text(baptism_offset_x, field_offset_y + field_offset_y_diff, godparent_text)
      baptism_draw.text(baptism_offset_x, field_offset_y + field_offset_y_diff * 2, presbyter_text)

      baptism_draw.draw(canvas)

      file_path = 'tmp/card.png'

      canvas.write(file_path)

      send_file file_path, type: 'image/png', disposition: 'inline'
    end

    def id_card_back
      font_path = '/Users/lucyxu/RubymineProjects/catholic/DFKai-SB.ttf'

      # Card b-side
      canvas_back = Magick::ImageList.new
      canvas_back.new_image(368, 224)
      background_back = canvas_back[0]

      # Draw church
      church = Magick::Image.read('/Users/lucyxu/RubymineProjects/catholic/asset/天主堂水彩畫.png').first
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

      back_file_path = 'tmp/card_back.png'

      canvas_back.write(back_file_path)

      send_file back_file_path, type: 'image/png', disposition: 'inline'
    end

    private

    def find_parishioner
      @parishioner = Parishioner.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Parishioner not found' }, status: :not_found
    end

    def find_baptism
      @baptism = Baptism.find_by_parishioner_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Baptism not found' }, status: :not_found
    end

    def parishioner_params
      params.permit(%i[
                      name gender birth_at postal_code address home_number
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
  end
end
