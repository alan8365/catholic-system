# frozen_string_literal: true

module Api
  class ReportsController < ApplicationController
    before_action :authorize_request, except: %i[]

    def regular_donation_monthly_report
      authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      return render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(%r{^\d{4}/\d{1,2}$})

      require 'axlsx'
      # Date process
      year, month = date.split('/').map(&:to_i)
      monthly_report_data = get_monthly_report_array(year, month)

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

    def regular_donation_yearly_report
      # authorize! :read, RegularDonation

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

        monthly_report_data = get_monthly_report_array(year, month)
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
      yearly_report_data = get_yearly_report_array(year)

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

    def special_donation_event_report
      authorize! :read, SpecialDonation

      event_id = params[:event_id]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      @event = Event.find_by_id!(event_id)

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

    private

    # @param [Integer] year
    # @return [Array]
    def get_yearly_report_array(year)
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

    # @param [Integer] year
    # @param [Integer] month
    # @return [Array]
    def get_monthly_report_array(year, month)
      all_sunday, all_sunday_str = get_all_sunday_in_month(month, year)

      # Results array process
      summation_str = "#{month}月份總計"
      all_col_name = ['家號', '姓名', *all_sunday_str, summation_str]
      row_hash, col_hash, results = report_data_init(all_col_name)

      # Donation amount
      @regular_donations = RegularDonation
                           .joins(:household)
                           .where('household.guest' => false)
                           .where('regular_donations.donation_at' => all_sunday)

      @regular_donations.each do |regular_donation|
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

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
