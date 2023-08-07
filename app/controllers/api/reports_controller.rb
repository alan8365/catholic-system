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

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(/^\d{4}$/)

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

        wb.add_worksheet(name: "#{month}月") do |sheet|
          monthly_report_data.each do |row|
            # Parishioner summation added
            row[-1] = row[2..].sum(&:to_i) if row[-1].nil?

            sheet.add_row row
          end
        end
      end

      # Results array process
      yearly_report_data = get_yearly_adr_array(year)

      wb.add_worksheet(name: '年度總帳') do |sheet|
        yearly_report_data.each do |row|
          sheet.add_row row
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

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(%r{^\d{4}/\d{1,2}$})

      require 'axlsx'
      # Date process
      year, month = date.split('/').map(&:to_i)
      monthly_report_data = get_monthly_rdr_array(year, month)

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        monthly_report_data.each do |result|
          sheet.add_row result
        end

        # Merge cell of summation
        (-3..-1).each do |i|
          sheet.merge_cells sheet.rows[i].cells[(0..1)]
        end
      end

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

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(/^\d{4}$/)

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

        wb.add_worksheet(name: "#{month}月") do |sheet|
          monthly_report_data.each do |row|
            # Parishioner summation added
            row[-1] = row[2..].sum(&:to_i) if row[-1].nil?

            sheet.add_row row
          end

          # Merge cell of summation
          (-3..-1).each do |i|
            sheet.merge_cells sheet.rows[i].cells[(0..1)]
          end
        end
      end

      # Results array process
      yearly_report_data = get_yearly_rdr_array(year)

      wb.add_worksheet(name: '年度奉獻明細') do |sheet|
        yearly_report_data.each do |row|
          sheet.add_row row
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

      @event = Event.find_by_id!(event_id)

      results = get_sdr_array(event_id)

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each do |result|
          sheet.add_row result
        end

        # Merge cell of summation
        sheet.merge_cells sheet.rows[-2].cells[(0..4)]
        sheet.merge_cells sheet.rows[-1].cells[(0..2)]
        sheet.merge_cells sheet.rows[-1].cells[(3..4)]
      end

      if is_test
        render json: results, status: :ok
      else
        date_str = @event.start_at.strftime('%Y年%m月')
        send_data(axlsx_package.to_stream.read, filename: "#{date_str}#{@event.name}奉獻.xlsx",
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Event not found' }, status: :not_found
    end

    # TODO: the example xlsx file have undefined part
    def sd_yearly_report
      authorize! :read, SpecialDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(/^\d{4}$/)

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
          event_report_data.each do |result|
            sheet.add_row result
          end

          # Merge cell of summation
          sheet.merge_cells sheet.rows[-2].cells[(0..4)]
          sheet.merge_cells sheet.rows[-1].cells[(0..2)]
          sheet.merge_cells sheet.rows[-1].cells[(3..4)]
        end
      end

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        yearly_report_data.each do |result|
          sheet.add_row result
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

    def rd_receipt_register
      authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(/^\d{4}$/)

      year = date.to_i

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, 12, -1)

      date_range = begin_date..end_date

      col_str = %w[編號 收據開立姓名或公司行號 金額 身分證字號或統一編號]
      col_str_index = col_str.each_index.map { |e| e }

      all_home_number = Household
                        .where('guest' => false)
                        .ids
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

      parishioner_donations = RegularDonation
                              .joins(household: :head_of_household)
                              .where(donation_at: date_range)
                              .where('household.guest' => false)
                              .group('strftime("%y", donation_at), household.home_number')
                              .order('household.home_number')
                              .pluck('household.home_number, parishioners.name, sum(donation_amount)')

      parishioner_donations.each do |e|
        row_index = row_hash[e[0]]

        3.times do |i|
          results[row_index][i] = e[i]
        end
      end

      axlsx_package = Axlsx::Package.new
      wb = axlsx_package.workbook

      wb.add_worksheet(name: 'Worksheet 1') do |sheet|
        results.each do |result|
          sheet.add_row result
        end

        sheet.merge_cells sheet.rows[0].cells[(0..3)]
        sheet.merge_cells sheet.rows[1].cells[(0..3)]
        sheet.merge_cells sheet.rows[-1].cells[(0..3)]
        sheet.merge_cells sheet.rows[-2].cells[(0..3)]
        sheet.merge_cells sheet.rows[-3].cells[(0..3)]
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

      @parishioners = if finding_params.empty?
                        Parishioner.all
                      else
                        Parishioner.where(id: finding_params)
                      end

      all_parishioner_id = @parishioners.map(&:id)
      all_parishioner_id_index = all_parishioner_id.each_index.map { |e| e + 1 }

      all_col_name = %w[教友編號 名稱 性別 生日
                        家號 郵遞區號 地址
                        父親 母親 家機 手機
                        國籍 職業 公司名稱
                        遷入時間 原始堂區
                        遷出時間 遷出原因 遷出堂區
                        備註]
      all_col_name_org = %w[id name gender birth_at
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

      @parishioners.each do |e|
        row_index = row_hash[e.id]

        all_col_name_org.each do |col_name|
          col_index = col_hash[col_name]

          results[row_index][col_index] = e[col_name]
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
        send_data(axlsx_package.to_stream.read, filename: '教友資料.xlsx',
                                                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    private

    def get_yearly_sdr_array(events)
      all_event_name = events.map(&:name)
      col_str = ['家號', '姓名', *all_event_name, '其他奉獻']
      col_str_index = col_str.each_index.map { |e| e }

      # Yearly report size setting
      all_household = Household
                      .left_outer_joins(:head_of_household)
                      .where('guest' => false)
                      .order('households.home_number')
                      .pluck('households.home_number, parishioners.name')
      all_household_index = all_household.each_index.map { |e| e + 1 }

      row_hash = Hash[all_household.map { |e| e[0] }.zip(all_household_index)]
      col_hash = Hash[col_str.zip(col_str_index)]

      yearly_report_data = Array.new(row_hash.size + 4) { Array.new(col_hash.size) }

      # Yearly report data fixed field filling
      sum_formula = []
      named_sum_formula = []

      (3..col_hash.size).each do |e|
        c_name = get_excel_column_name(e)
        r_number = yearly_report_data.size - 1

        sum_formula << "=SUM(#{c_name}#{r_number - 1}:#{c_name}#{r_number})"
        named_sum_formula << "=SUM(#{c_name}2:#{c_name}#{row_hash.size + 1})"
      end

      named_sum_str = ['', '記名總額', *named_sum_formula]

      yearly_report_data[0] = col_str
      yearly_report_data[-3] = named_sum_str
      yearly_report_data[-2][1] = '善心總額'
      yearly_report_data[-1] = ['奉獻總額', nil, *sum_formula]

      row_hash.each do |home_number, row_index|
        yearly_report_data[row_index][0] = home_number
        yearly_report_data[row_index][1] = all_household[row_index - 1][1]
      end

      # Yearly report data IO getting
      all_sd = SpecialDonation
               .joins(:event, :household)
               .where('event.id' => events.ids)
               .where('household.guest' => false)
               .group('event.id, special_donations.home_number')
               .order('event.start_at')
               .pluck('event.name, special_donations.home_number, sum(special_donations.donation_amount)')

      all_gsd = SpecialDonation
                .joins(:event, :household)
                .where('event.id' => events.ids)
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

      yearly_report_data
    end

    def get_sdr_array(event_id)
      event_donation = SpecialDonation
                       .left_joins(:event, household: :head_of_household)
                       .where('event.id' => event_id)
                       .order(:donation_at)
                       .pluck('special_donations.home_number, donation_at, parishioners.name, donation_amount, special_donations.comment')

      all_home_number = event_donation.map { |e| e[0] }
      all_home_number_index = all_home_number.each_index.map { |e| e + 1 }

      all_col_name = %w[家號 日期 姓名 金額 備註]
      col_name_index = all_col_name.each_index.to_a

      row_hash = Hash[all_home_number.zip(all_home_number_index)]
      col_hash = Hash[all_col_name.zip(col_name_index)]

      results = Array.new(row_hash.size + 3) { Array.new(col_hash.size) }
      results[0] = all_col_name

      event_donation.each do |e|
        home_number = e[0]
        row_index = row_hash[home_number]

        e[1] = e[1].strftime('%m/%d')

        e[2] = '善心人士' if e[2].nil?

        5.times { |i| results[row_index][i] = e[i] }
      end

      results[-1][0] = '合計'
      results[-1][3] = event_donation.sum { |e| e[3] }
      results
    end

    # @param [Integer] year
    # @return [Array]
    def get_yearly_rdr_array(year)
      all_month_str = (1..12).to_a.map { |e| "#{e}月" }

      all_col_name = ['家號', '姓名', *all_month_str, '戶年度奉獻總計']
      row_hash, col_hash, yearly_report_data = report_data_init(all_col_name)

      begin_date = Date.civil(year, 1, 1)
      end_date = Date.civil(year, -1, -1)

      date_range = begin_date..end_date

      monthly_donation_summations = RegularDonation
                                    .joins(:household)
                                    .where(donation_at: date_range)
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

      donation_summations = RegularDonation
                            .joins(:household)
                            .where(donation_at: date_range)
                            .where('household.guest' => false)
                            .group('strftime("%m", donation_at)')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = RegularDonation
                                  .joins(:household)
                                  .where(donation_at: date_range)
                                  .where('household.guest' => true)
                                  .group('strftime("%m", donation_at)')
                                  .order('donation_at')
                                  .pluck('donation_at, sum(donation_amount)')

      yearly_report_data[-3][0] = '有名氏合計'
      yearly_report_data[-2][0] = '隱名氏合計'
      yearly_report_data[-1][0] = '總合計'

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

      yearly_report_data
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

      monthly_donation_summations = RegularDonation
                                    .joins(:household)
                                    .where(donation_at: date_range)
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

      donation_summations = RegularDonation
                            .joins(:household)
                            .where(donation_at: date_range)
                            .where('household.guest' => false)
                            .group('strftime("%m", donation_at)')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = RegularDonation
                                  .joins(:household)
                                  .where(donation_at: date_range)
                                  .where('household.guest' => true)
                                  .group('strftime("%m", donation_at)')
                                  .order('donation_at')
                                  .pluck('donation_at, sum(donation_amount)')

      special_donation_summations = SpecialDonation
                                    .joins(:household)
                                    .where(donation_at: date_range)
                                    .where('household.guest' => false)
                                    .group('strftime("%y", donation_at), household.home_number')
                                    .order('donation_at')
                                    .pluck('household.home_number, sum(donation_amount)')

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

      # Guest and name donation sum
      col_hash.map do |k, col_index|
        guest_donation = yearly_report_data[-2][col_index].to_i
        name_donation = yearly_report_data[-3][col_index].to_i

        yearly_report_data[-1][col_index] = guest_donation + name_donation if k.match?(/\d{1,2}月/)
      end

      # Parishioner special donation summation
      special_donation_summations.each do |e|
        home_number = e[0]
        amount = e[1]

        row_index = row_hash[home_number]
        col_index = -2

        yearly_report_data[row_index][col_index] = amount
      end

      # Parishioner donation summation
      yearly_report_data.each do |row|
        row[-3] = row[2..].sum(&:to_i) if row[-3].nil?
        row[-1] = row[-3..-2].sum(&:to_i) if row[-1].nil?
      end

      yearly_report_data
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
      @special_donations = RegularDonation
                           .joins(:household)
                           .where('household.guest' => false)
                           .where('regular_donations.donation_at' => all_sunday)

      @special_donations.each do |regular_donation|
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

      donation_summations = RegularDonation
                            .joins(:household)
                            .where(donation_at: all_sunday)
                            .where('household.guest' => false)
                            .group('donation_at')
                            .order('donation_at')
                            .pluck('donation_at, sum(donation_amount)')

      guest_donation_summations = RegularDonation
                                  .joins(:household)
                                  .where(donation_at: all_sunday)
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
      results.each do |result|
        result[-1] = result[2..].sum(&:to_i) if result[-1].nil?
      end

      results
    end

    def report_data_init(all_col_name)
      all_household = Household.where('guest != true').order('home_number')
      all_home_number = all_household.map { |e| e['home_number'] }
      home_number_index = all_home_number.each_index.to_a.map { |i| i + 1 }

      col_name_index = all_col_name.each_index.to_a

      row_hash = Hash[all_home_number.zip(home_number_index)]
      col_hash = Hash[all_col_name.zip(col_name_index)]

      results = Array.new(row_hash.size + 4) { Array.new(col_hash.size) }
      results[0] = all_col_name

      all_household.each do |household|
        home_number = household['home_number']
        head_of_household = household.head_of_household
        name = head_of_household&.name

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

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
