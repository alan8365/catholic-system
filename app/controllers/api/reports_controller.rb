# frozen_string_literal: true

module Api
  class ReportsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[]

    def ad_yearly_report
      authorize! :read, RegularDonation
      authorize! :read, SpecialDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])
      query = params[:any_field]

      return render json: { errors: I18n.t('invalid_date') }, status: :bad_request unless date&.match?(/^\d{4}$/)

      require 'axlsx'

      year = date.to_i
      all_month = (1..12).to_a

      every_monthly_report = {}

      p = Axlsx::Package.new
      wb = p.workbook

      all_month.each do |month|
        month_string = month.to_s.rjust(2, '0')
        date_string = "#{year}/#{month_string}"

        monthly_report_data = get_monthly_rdr_array(year, month)
        every_monthly_report[date_string] = monthly_report_data

        rd_monthly_xlsx_fill(monthly_report_data, wb, "#{month}月")
      end

      # Results array process
      yearly_report_data = get_yearly_adr_array(year)

      unless query.nil?
        temp_middle = yearly_report_data[1..-4].select do |e|
          e.join('').include? query
        end

        yearly_report_data = yearly_report_data[..0] + temp_middle + yearly_report_data[-3..]
      end

      wb.add_worksheet(name: '年度總帳') do |sheet|
        yearly_report_data.each do |row|
          currency_array = ['currency'] * (row.size - 2)
          style_type_index = ['', '', *currency_array]
          style = get_xlsx_style(wb, row.size, style_type_index)
          sheet.add_row row, style:
        end
      end

      if is_test
        render json: [every_monthly_report, yearly_report_data], status: :ok
      else
        send_data(p.to_stream.read, filename: "#{year}-年度總帳.xlsx",
                                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def rd_monthly_report
      authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      unless date&.match?(%r{^\d{4}/\d{1,2}$})
        return render json: { errors: I18n.t('invalid_date') },
                      status: :bad_request
      end

      require 'axlsx'
      # Date process
      year, month = date.split('/').map(&:to_i)
      monthly_report_data = get_monthly_rdr_array(year, month)

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook
      rd_monthly_xlsx_fill(monthly_report_data, wb, 'Worksheet 1')

      if is_test
        render json: monthly_report_data, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: "#{date}主日奉獻統計資料.xlsx",
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def rd_yearly_report
      authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: I18n.t('invalid_date') }, status: :bad_request unless date&.match?(/^\d{4}$/)

      require 'axlsx'

      year = date.to_i
      all_month = (1..12).to_a

      every_monthly_report = {}

      p = Axlsx::Package.new
      wb = p.workbook

      all_month.each do |month|
        month_string = month.to_s.rjust(2, '0')
        date_string = "#{year}/#{month_string}"

        monthly_report_data = get_monthly_rdr_array(year, month)
        every_monthly_report[date_string] = monthly_report_data

        rd_monthly_xlsx_fill(monthly_report_data, wb, "#{month}月")
      end

      # Results array process
      yearly_report_data = get_yearly_rdr_array(year)

      wb.add_worksheet(name: '年度奉獻明細') do |sheet|
        yearly_report_data.each do |row|
          currency_array = ['currency'] * (row.size - 2)
          style_type_index = ['', '', *currency_array]
          style = get_xlsx_style(wb, row.size, style_type_index)
          sheet.add_row row, style:
        end
      end

      if is_test
        render json: [every_monthly_report, yearly_report_data], status: :ok
      else
        send_data(p.to_stream.read, filename: "每月_#{year}教友奉獻明細表.xlsx",
                                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def sd_event_report
      authorize! :read, SpecialDonation

      event_id = params[:event_id]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])
      is_announce = ActiveModel::Type::Boolean.new.cast(params[:announce])

      @event = Event.find_by_id!(event_id)

      results = get_sdr_array(event_id, is_announce:)

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        sd_event_worksheet(sheet, wb, results)
      end

      if is_test
        render json: results, status: :ok
      else
        date_str = @event.start_at.strftime('%Y年%m月')
        send_data(axlsx_package.to_stream.read, filename: "#{date_str}#{@event.name}奉獻.xlsx",
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('event_not_found') }, status: :not_found
    end

    def sd_yearly_report
      authorize! :read, SpecialDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: I18n.t('invalid_date') }, status: :bad_request unless date&.match?(/^\d{4}$/)

      require 'axlsx'

      year = date.to_i

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, 12, -1)

      date_range = begin_date..end_date

      @events = Event
                .where('start_at' => date_range)
                .order('start_at')

      yearly_report_data = get_yearly_sdr_array(@events)

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      @events.each do |event|
        event_id = event.id

        event_report_data = get_sdr_array(event_id)

        wb.add_worksheet(name: event.name) do |sheet|
          sd_event_worksheet(sheet, wb, event_report_data)
        end
      end

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        yearly_report_data.each do |row|
          currency_array = ['currency'] * (row.size - 2)
          style_type_index = ['', '', *currency_array]
          style = get_xlsx_style(wb, row.size, style_type_index)
          sheet.add_row row, style:
        end

        # Merge cell of summation
        sheet.merge_cells sheet.rows[-1].cells[(0..1)]
      end

      if is_test
        render json: yearly_report_data, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: "#{date}-其他奉獻.xlsx",
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def receipt_register
      authorize! :read, RegularDonation

      date = params[:date]
      query = params[:any_field]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: I18n.t('invalid_date') }, status: :bad_request unless date&.match?(/^\d{4}$/)

      year = date.to_i

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, 12, -1)

      date_range = begin_date..end_date

      regular_donations = RegularDonation
                          .left_joins(household: :head_of_household)
                          .where(donation_at: date_range)
                          .where(receipt: true)
                          .where('household.guest' => false)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)
                          .group('strftime("%y", donation_at), household.home_number')
                          .order('household.home_number')
                          .pluck('household.home_number, parishioners.last_name, parishioners.first_name, sum(donation_amount), household.comment')

      special_donations = SpecialDonation
                          .left_joins(household: :head_of_household)
                          .where(donation_at: date_range)
                          .where(receipt: true)
                          .where('household.guest' => false)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)
                          .group('strftime("%y", donation_at), household.home_number')
                          .order('household.home_number')
                          .pluck('household.home_number, parishioners.last_name, parishioners.first_name, sum(donation_amount), household.comment')

      parishioner_donations = regular_donations + special_donations

      col_str = %w[編號 收據開立姓名或公司行號 金額 身分證字號或統一編號]
      col_str_index = col_str.each_index.map { |e| e }

      all_home_number = Household.where('is_archive' => false).map(&:home_number)
      all_home_number_index = all_home_number.each_index.map { |e| e + 3 }

      row_hash = Hash[all_home_number.zip(all_home_number_index)]
      col_hash = Hash[col_str.zip(col_str_index)]

      results = Array.new(row_hash.size + 7) { Array.new(col_hash.size) }

      results[0][0] = "附表一          #{year - 1911}年捐款收據名冊                堂區:彰化天主堂"
      results[1][0] = '捐款意向:'
      results[2] = col_str

      results[-4][0] = '合計金額'
      results[-3][0] = '* 身分證字號是為將捐款資料上傳國稅局時使用，方便個人網路申報所得，'
      results[-2][0] = '若無需代為上傳國稅局，可以不提供身分證字號。'
      results[-1][0] = '主任司鐸:                  會計:                  製表人:'

      results.each_with_index do |_row, index|
        results[index][2] = 0 if index > 2 && index < results.size - 4
      end

      parishioner_donations.each do |e|
        row_index = row_hash[e[0]]

        name = if e[1].present?
                 "#{e[1]}#{e[2]}"
               else
                 e[4]
               end

        results[row_index][0] = e[0]
        results[row_index][1] = name
        results[row_index][2] += e[3]
      end

      unless query.nil?
        temp_middle = results[2..-4].select do |e|
          e.join('').include? query
        end

        results = results[..1] + temp_middle + results[-4..]
      end

      results = exclude_zero_value(2, -4, results, -2)

      summation = results[2..-4].sum { |e| e[2].to_i }
      results[-4][2] = summation

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each_with_index  do |row, index|
          style_type_index = if (index > 1) && (index < results.size - 3)
                               %w[title normal currency currency]
                             elsif index.zero?
                               %w[title-no-border]
                             elsif index == 2
                               %w[title title title title]
                             else
                               %w[no-border no-border no-border no-border]
                             end
          style = get_xlsx_style(wb, row.size, style_type_index)
          sheet.add_row row, style:, height: 27, widths: [10, 30, 20, 40]
        end

        sheet.merge_cells sheet.rows[0].cells[(0..3)]
        sheet.merge_cells sheet.rows[1].cells[(0..3)]
        sheet.merge_cells sheet.rows[-4].cells[(0..1)]
        sheet.merge_cells sheet.rows[-3].cells[(0..3)]
        sheet.merge_cells sheet.rows[-2].cells[(0..3)]
        sheet.merge_cells sheet.rows[-1].cells[(0..3)]
      end

      if is_test
        render json: results, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: "#{year}-捐款名冊.xlsx",
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def parishioner_report
      authorize! :read, Parishioner

      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])
      finding_params = params['pid'] || []

      @parishioners = Parishioner.all

      @parishioners = @parishioners.where(id: finding_params) if finding_params.present?

      all_parishioner_id = @parishioners.map(&:id)
      all_parishioner_id_index = all_parishioner_id.each_index.map { |e| e + 1 }

      all_col_name = %w[領洗編號 名稱 性別 生日
                        家號 郵遞區號 地址
                        父親 母親 家機 手機
                        國籍 職業 公司名稱
                        遷入時間 原始堂區
                        遷出時間 遷出原因 遷出堂區
                        備註]
      all_col_name_org = %w[serial_number name gender birth_at
                            home_number postal_code address
                            father mother home_phone mobile_phone
                            nationality profession company_name
                            move_in_date original_parish
                            move_out_date move_out_reason destination_parish
                            comment]
      col_name_index = all_col_name_org.each_index.to_a

      row_hash = Hash[all_parishioner_id.zip(all_parishioner_id_index)]
      col_hash = Hash[all_col_name_org.zip(col_name_index)]

      results = Array.new(row_hash.size + 1) { Array.new(col_hash.size) }
      results[0] = all_col_name

      @parishioners.each do |parishioners|
        row_index = row_hash[parishioners.id]

        all_col_name_org.each do |col_name|
          col_index = col_hash[col_name]

          results[row_index][col_index] = if col_name == 'name'
                                            parishioners.full_name
                                          else
                                            parishioners[col_name]
                                          end
        end
        results[row_index][0] = parishioners.baptism&.serial_number
      end

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each do |result|
          sheet.add_row result
        end
      end

      if is_test
        render json: results, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: '教友資料.xlsx',
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def rd_report
      authorize! :read, RegularDonation

      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])
      finding_params = params['ids'] || []

      regular_donations = RegularDonation.all
                                         .left_joins(household: :head_of_household)
                                         .select(%w[regular_donations.* parishioners.last_name
                                                    parishioners.first_name households.head_of_household],
                                                 'households.comment as hc')

      unless finding_params.empty?
        regular_donations = regular_donations
                            .where(id: finding_params)
      end

      all_regular_donation_id = regular_donations.map(&:id)
      all_regular_donation_id_index = all_regular_donation_id.each_index.map { |e| e + 1 }

      all_col_name = %w[家號 姓名/稱呼 日期 金額 備註]
      all_col_name_org = %w[home_number name donation_at donation_amount comment]

      col_name_index = all_col_name_org.each_index.to_a

      row_hash = Hash[all_regular_donation_id.zip(all_regular_donation_id_index)]
      col_hash = Hash[all_col_name_org.zip(col_name_index)]

      results = Array.new(row_hash.size + 1) { Array.new(col_hash.size) }
      results[0] = all_col_name

      regular_donations.each do |regular_donation|
        row_index = row_hash[regular_donation.id]

        data_hash = regular_donation.as_json
        data_hash['name'] = if regular_donation.head_of_household.nil?
                              regular_donation.hc
                            else
                              "#{regular_donation.last_name}#{regular_donation.first_name}"
                            end

        all_col_name_org.each do |col_name|
          col_index = col_hash[col_name]

          results[row_index][col_index] = data_hash[col_name]
        end
      end

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each do |result|
          sheet.add_row result
        end
      end

      if is_test
        render json: results, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: '主日捐款資料.xlsx',
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    def sd_report
      authorize! :read, SpecialDonation

      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])
      finding_params = params['ids'] || []

      @special_donations = SpecialDonation.all
                                          .left_joins(household: :head_of_household)
                                          .select(%w[special_donations.* parishioners.last_name
                                                     parishioners.first_name households.head_of_household],
                                                  'households.comment as hc')

      unless finding_params.empty?
        @special_donations = @special_donations
                             .where(id: finding_params)
      end

      all_special_donation_id = @special_donations.map(&:id)
      all_special_donation_id_index = all_special_donation_id.each_index.map { |e| e + 1 }

      all_col_name = %w[家號 姓名/稱呼 日期 金額 備註]
      all_col_name_org = %w[home_number name donation_at donation_amount comment]

      col_name_index = all_col_name_org.each_index.to_a

      row_hash = Hash[all_special_donation_id.zip(all_special_donation_id_index)]
      col_hash = Hash[all_col_name_org.zip(col_name_index)]

      results = Array.new(row_hash.size + 1) { Array.new(col_hash.size) }
      results[0] = all_col_name

      @special_donations.each do |special_donation|
        row_index = row_hash[special_donation.id]

        data_hash = special_donation.as_json
        data_hash['name'] = if special_donation.head_of_household.nil?
                              special_donation.hc
                            else
                              "#{special_donation.last_name}#{special_donation.first_name}"
                            end

        all_col_name_org.each do |col_name|
          col_index = col_hash[col_name]

          results[row_index][col_index] = data_hash[col_name]
        end
      end

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each do |result|
          sheet.add_row result
        end
      end

      if finding_params.empty?
        render json: { errors: I18n.t('please_choose_a_record') },
               status: :bad_request
      elsif is_test
        render json: results, status: :ok
      else
        send_data(axlsx_package.to_stream.read, filename: '特殊捐款資料.xlsx',
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    private

    def sd_event_worksheet(sheet, workbook, results)
      results.each_with_index do |row, index|
        if index.zero?
          style_type_index = ['title']
        else
          currency_array = ['currency'] * (row.size - 3)
          style_type_index = ['', '', '', *currency_array]
        end

        style = get_xlsx_style(workbook, row.size, style_type_index)
        sheet.add_row row, style:
      end

      # Merge cell of summation
      sheet.merge_cells sheet.rows[0].cells[(0..4)]
      sheet.merge_cells sheet.rows[-2].cells[(0..4)]
      sheet.merge_cells sheet.rows[-1].cells[(0..2)]
      sheet.merge_cells sheet.rows[-1].cells[(3..4)]
    end

    def get_xlsx_style(workbook, array_size, style_type_index)
      border = { style: :thin, color: '000000',
                 edges: %i[top bottom left right] }
      font_name = '標楷體'
      sz = 14

      currency_style = workbook.styles.add_style({ num_fmt: 3,
                                                   alignment: { horizontal: :right, vertical: :center },
                                                   border:,
                                                   font_name:,
                                                   sz: })
      normal_style = workbook.styles.add_style({ num_fmt: 1,
                                                 alignment: { horizontal: :left, vertical: :center },
                                                 border:,
                                                 font_name:,
                                                 sz: })
      title_style = workbook.styles.add_style({ num_fmt: 1,
                                                alignment: { horizontal: :center, vertical: :center },
                                                border:,
                                                font_name:,
                                                sz: })
      title_no_border_style = workbook.styles.add_style({ num_fmt: 1,
                                                          alignment: { horizontal: :center, vertical: :center },
                                                          font_name:,
                                                          sz: })
      no_border_style = workbook.styles.add_style({ num_fmt: 1,
                                                    alignment: { horizontal: :left, vertical: :center },
                                                    font_name:,
                                                    sz: })
      results = Array.new(array_size)

      style_type_index.each_with_index do |e, i|
        results[i] = case e
                     when 'currency'
                       currency_style
                     when 'title'
                       title_style
                     when 'title-no-border'
                       title_no_border_style
                     when 'no-border'
                       no_border_style
                     else
                       normal_style
                     end
      end

      results
    end

    def rd_monthly_xlsx_fill(monthly_report_data, workbook, worksheet_name)
      workbook.add_worksheet(name: worksheet_name) do |sheet|
        monthly_report_data.each do |row|
          currency_array = ['currency'] * (row.size - 2)
          style_type_index = ['', '', *currency_array]
          style = get_xlsx_style(workbook, row.size, style_type_index)
          sheet.add_row row, style:
        end

        # Merge cell of summation
        (-3..-1).each do |i|
          sheet.merge_cells sheet.rows[i].cells[(0..1)]
        end
      end
    end

    def get_yearly_sdr_array(events)
      all_event_name = events.map(&:name)
      all_col_name = ['家號', '姓名', *all_event_name, '總計']

      # Yearly report size setting
      row_hash, col_hash, yearly_report_data = report_data_init(all_col_name)

      # Yearly report data initialization
      all_sum = [0] * (col_hash.size - 2)
      named_sum = [0] * (col_hash.size - 2)
      guest_sum = [0] * (col_hash.size - 2)

      yearly_report_data[-3] = ['', '記名總額', *named_sum]
      yearly_report_data[-2] = ['', '善心總額', *guest_sum]
      yearly_report_data[-1] = ['奉獻總額', nil, *all_sum]

      # Yearly report data IO getting
      special_donations = SpecialDonation
                          .joins(:event, :household)
                          .where('event.id' => events.ids)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)

      all_sd = special_donations
               .where('household.guest' => false)
               .group('event.id, special_donations.home_number')
               .order('event.start_at')
               .pluck('event.name, special_donations.home_number, sum(special_donations.donation_amount)')

      all_gsd = special_donations
                .where('household.guest' => true)
                .group('event.id')
                .order('event.start_at')
                .pluck('event.name, sum(special_donations.donation_amount)')

      # Yearly report data donation filling
      all_sd.each do |sd|
        event_name = sd[0]
        home_number = sd[1]
        amount = sd[2]

        row_index = row_hash[home_number]
        col_index = col_hash[event_name]

        yearly_report_data[row_index][col_index] = amount
        yearly_report_data[-3][col_index] += amount
      end

      all_gsd.each do |gsd|
        event_name = gsd[0]
        amount = gsd[1]

        col_index = col_hash[event_name]
        yearly_report_data[-2][col_index] = amount
      end

      # Yearly report data summing
      yearly_report_data.each do |row|
        row[-1] = row[2..].sum(&:to_i) if row[-1].nil?
      end

      header_index = 1
      footer_index = -3

      exclude_zero_value(header_index, footer_index, yearly_report_data)
    end

    def get_sdr_array(event_id, is_announce: false)
      event_donation = SpecialDonation
                       .left_joins(:event, household: :head_of_household)
                       .where('event.id' => event_id)
                       .where(general_where_rule_hash)
                       .where(general_where_rule_array)
                       .where('household.is_archive' => false)
                       .order(:donation_at)
                       .pluck('special_donations.home_number, donation_at,
parishioners.last_name, parishioners.first_name,
donation_amount, special_donations.comment,
household.comment')

      all_home_number = event_donation.map { |e| e[0] }
      all_home_number_index = all_home_number.each_index.map { |e| e + 2 }

      all_col_name = %w[家號 日期 姓名 金額 備註]
      col_name_index = all_col_name.each_index.to_a

      row_hash = Hash[all_home_number.zip(all_home_number_index)]
      col_hash = Hash[all_col_name.zip(col_name_index)]

      results = Array.new(row_hash.size + 4) { Array.new(col_hash.size) }
      results[1] = all_col_name

      summation = 0
      event_donation.each do |e|
        home_number = e[0]
        row_index = row_hash[home_number]

        name = if e[2].nil?
                 e[6]
               elsif is_announce && !/[a-zA-Z]+/.match?(e[3])
                 e[3][0] = 'Ｏ'
                 "#{e[2]}#{e[3]}"
               else
                 "#{e[2]}#{e[3]}"
               end

        e[1] = e[1].strftime('%m/%d')
        e[2] = name
        e[3] = e[4]
        e[4] = e[5]

        5.times do |i|
          results[row_index][i] = e[i]
        end

        summation += e[3]
      end

      results[0][0] = "#{Event.find_by_id(event_id).name}奉獻"
      results[-1][0] = '合計'
      results[-1][3] = summation
      results
    end

    def get_yearly_rdr_array(year)
      all_month_str = (1..12).to_a.map { |e| "#{e}月" }

      all_col_name = ['家號', '姓名', *all_month_str, '戶年度奉獻總計']
      row_hash, col_hash, yearly_report_data = report_data_init(all_col_name)

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, -1, -1)

      date_range = begin_date..end_date

      regular_donations = RegularDonation
                          .joins(:household)
                          .where(donation_at: date_range)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)

      monthly_donation_summations = regular_donations
                                    .group('strftime("%m", donation_at), household.home_number')
                                    .order('donation_at')
                                    .pluck('donation_at, household.home_number, sum(donation_amount)')

      donation_summations = regular_donations
                            .where('household.guest' => false)
                            .group('strftime("%m", donation_at)')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = regular_donations
                                  .where('household.guest' => true)
                                  .group('strftime("%m", donation_at)')
                                  .order('donation_at')
                                  .pluck('donation_at, sum(donation_amount)')

      yearly_report_data[-3][0] = '有名氏合計'
      yearly_report_data[-2][0] = '隱名氏合計'
      yearly_report_data[-1][0] = '總合計'

      monthly_donation_summations.each do |e|
        month = "#{e[0].month}月"
        home_number = e[1]
        amount = e[2]

        row_index = row_hash[home_number]
        col_index = col_hash[month]

        yearly_report_data[row_index][col_index] = amount
      end

      donation_summations.map do |e|
        month = "#{e[0].month}月"
        amount = e[1]

        col_index = col_hash[month]

        yearly_report_data[-3][col_index] = amount
      end

      guest_donation_summations.map do |e|
        month = "#{e[0].month}月"
        amount = e[1]

        col_index = col_hash[month]

        yearly_report_data[-2][col_index] = amount
      end

      col_hash.map do |k, col_index|
        guest_donation = yearly_report_data[-2][col_index].to_i
        name_donation = yearly_report_data[-3][col_index].to_i

        yearly_report_data[-1][col_index] = guest_donation + name_donation if k.match?(/\d{1,2}月/)
      end

      # Parishioner summation added
      yearly_report_data.each do |row|
        row[-1] = row[2..].sum(&:to_i) if row[-1].nil?
      end

      exclude_zero_value(1, -3, yearly_report_data)
    end

    # Get all donation report
    # TODO refactor with get_yearly_rdr_array
    def get_yearly_adr_array(year)
      all_month_str = (1..12).to_a.map { |e| "#{e}月" }

      all_col_name = ['家號', '姓名', *all_month_str, '年度主日奉獻總額', '個人其他奉獻總額', '年度總計']
      row_hash, col_hash, yearly_report_data = report_data_init(all_col_name)

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, -1, -1)

      date_range = begin_date..end_date

      regular_donations = RegularDonation
                          .joins(:household)
                          .where(donation_at: date_range)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)

      monthly_donation_summations = regular_donations
                                    .where('household.guest' => false)
                                    .group('strftime("%m", donation_at), household.home_number')
                                    .order('donation_at')
                                    .pluck('donation_at, household.home_number, sum(donation_amount)')

      monthly_donation_summations.each do |e|
        month = "#{e[0].month}月"
        home_number = e[1]
        amount = e[2]

        row_index = row_hash[home_number]
        col_index = col_hash[month]

        yearly_report_data[row_index][col_index] = amount
      end

      donation_summations = regular_donations
                            .where('household.guest' => false)
                            .group('strftime("%m", donation_at)')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = regular_donations
                                  .where('household.guest' => true)
                                  .group('strftime("%m", donation_at)')
                                  .order('donation_at')
                                  .pluck('donation_at, sum(donation_amount)')

      special_donations = SpecialDonation
                          .joins(:household)
                          .where(donation_at: date_range)
                          .where(general_where_rule_hash)
                          .where(general_where_rule_array)

      special_donation_summations = special_donations
                                    .where('household.guest' => false)
                                    .group('strftime("%y", donation_at), household.home_number')
                                    .order('donation_at')
                                    .pluck('household.home_number, sum(donation_amount)')

      guest_special_donation_summations = special_donations
                                          .where('household.guest' => true)
                                          .pluck('sum(donation_amount)')

      yearly_report_data[-3][0] = '單月份記名總額'
      yearly_report_data[-2][0] = '單月善心總額'
      yearly_report_data[-1][0] = '單月份奉獻總額'

      # Every month regular donation summation
      donation_summations.map do |e|
        month = "#{e[0].month}月"
        amount = e[1]

        col_index = col_hash[month]

        yearly_report_data[-3][col_index] = amount
      end

      # Every month guest regular donation summation
      guest_donation_summations.map do |e|
        month = "#{e[0].month}月"
        amount = e[1]

        col_index = col_hash[month]

        yearly_report_data[-2][col_index] = amount
      end

      # Parishioner special donation summation
      special_donation_summations.each do |e|
        home_number = e[0]
        amount = e[1]

        row_index = row_hash[home_number]
        col_index = -2

        yearly_report_data[row_index][col_index] = amount
      end

      # Parishioners special donation summation
      yearly_report_data[-3][-2] = special_donation_summations.map { |e| e[1] }.sum

      # Guest special donation summation
      yearly_report_data[-2][-2] = guest_special_donation_summations.sum

      # Parishioner donation summation
      yearly_report_data.each_with_index do |row, _index|
        row[-3] = row[2..13].sum(&:to_i) if row[-3].nil?
        row[-1] = row[-3..-2].sum(&:to_i) if row[-1].nil?
      end

      # Guest and name donation sum
      col_hash.map do |_k, col_index|
        guest_donation = yearly_report_data[-2][col_index].to_i
        name_donation = yearly_report_data[-3][col_index].to_i

        yearly_report_data[-1][col_index] = guest_donation + name_donation if col_index > 1
      end

      # Delete row if summation is 0
      header_index = 1
      footer_index = -3

      exclude_zero_value(header_index, footer_index, yearly_report_data)
    end

    # @param [Integer] year
    # @param [Integer] month
    # @return [Array]
    def get_monthly_rdr_array(year, month)
      all_sunday, all_sunday_str = get_all_sunday_in_month(month, year)

      # Results array process
      summation_str = "#{month}月份總計"
      all_col_name = ['家號', '姓名', *all_sunday_str, summation_str]
      row_hash, col_hash, results = report_data_init(all_col_name)

      # Donation amount
      regular_donations_base = RegularDonation
                               .joins(:household)
                               .where(general_where_rule_hash)
                               .where(general_where_rule_array)
                               .where(donation_at: all_sunday)

      regular_donations = regular_donations_base

      regular_donations.each do |regular_donation|
        home_number = regular_donation['home_number']

        donation_at = regular_donation['donation_at'].strftime('%m/%d')
        donation_at[2] = '/'

        donation_amount = regular_donation['donation_amount']

        # FIXME: donation_at not in all_sunday_str
        col_index = col_hash[donation_at]
        row_index = row_hash[home_number]

        next if col_index.nil?

        results[row_index][col_index] = donation_amount
      end

      donation_summations = regular_donations_base
                            .joins(:household)
                            .where('household.guest' => false)
                            .group('donation_at')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = regular_donations_base
                                  .where('household.guest' => true)
                                  .group('donation_at')
                                  .order('donation_at')
                                  .pluck('donation_at, sum(donation_amount)')

      results[-3][0] = '有名氏合計'
      results[-2][0] = '隱名氏合計'
      results[-1][0] = '總合計'
      donation_summations.map do |e|
        col_index = col_hash[e[0].strftime('%m/%d')]

        results[-3][col_index] = e[1]
      end

      guest_donation_summations.map do |e|
        col_index = col_hash[e[0].strftime('%m/%d')]

        results[-2][col_index] = e[1]
      end

      col_hash.map do |k, col_index|
        guest_donation = results[-2][col_index].to_i
        name_donation = results[-3][col_index].to_i

        results[-1][col_index] = guest_donation + name_donation if k.match?(%r{\d{2}/\d{2}})
      end

      # Parishioner summation added
      results.each_with_index do |result, _index|
        result[-1] = result[2..].sum(&:to_i) if result[-1].nil?
      end

      # Delete row if summation is 0
      header_index = 1
      footer_index = -3

      exclude_zero_value(header_index, footer_index, results)
    end

    def report_data_init(all_col_name)
      all_household = Household
                      .order('home_number')
      all_home_number = all_household.map { |e| e['home_number'] }
      home_number_index = all_home_number.each_index.to_a.map { |i| i + 1 }

      col_name_index = all_col_name.each_index.to_a

      row_hash = Hash[all_home_number.zip(home_number_index)]
      col_hash = Hash[all_col_name.zip(col_name_index)]

      results = Array.new(row_hash.size + 4) { Array.new(col_hash.size) }
      results[0] = all_col_name

      all_household.each do |household|
        home_number = household['home_number']
        if household.head_of_household.nil?
          name = household.comment
        else
          head_of_household = household.head_of_household
          name = head_of_household&.full_name
        end

        row_index = row_hash[home_number]
        results[row_index][0] = home_number
        results[row_index][1] = name
      end
      [row_hash, col_hash, results]
    end

    def get_all_sunday_in_month(month, year)
      begin_date = Date.civil(year, month, 1)
      end_date = Date.civil(year, month, -1)

      date_range = begin_date..end_date
      all_sunday = date_range.to_a.select { |k| k.wday.zero? }
      all_sunday_str = all_sunday.map { |k| k.strftime('%m/%d') }

      [all_sunday, all_sunday_str]
    end

    def get_excel_column_name(column_number)
      column_name = ''
      while column_number.positive?
        modulo = (column_number - 1) % 26
        column_name = ('A'.ord + modulo).chr + column_name
        column_number = (column_number - modulo) / 26
      end
      column_name
    end

    def exclude_zero_value(header_index, footer_index, report_data, check_col_index = -1)
      non_zero_report_data = report_data[..header_index - 1]

      report_data[header_index..footer_index - 1].map do |e|
        non_zero_report_data << e unless (e[check_col_index]).zero?
      end
      report_data[footer_index..].map do |e|
        non_zero_report_data << e
      end

      non_zero_report_data
    end

    def general_where_rule_hash
      {
        'household.is_archive' => false
      }
    end

    def general_where_rule_array
      [
        'household.head_of_household is not :head or (household.special = :special or household.guest = :guest)',
        { head: nil, special: true, guest: true }
      ]
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
