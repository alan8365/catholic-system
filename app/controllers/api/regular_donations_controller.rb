# frozen_string_literal: true

module Api
  class RegularDonationsController < ApplicationController
    before_action :authorize_request, except: %i[monthly_report yearly_report]
    before_action :find_regular_donation, except: %i[create index monthly_report yearly_report]

    # GET /regular_donations
    def index
      authorize! :read, RegularDonation
      query = params[:any_field]
      date = params[:date]

      if query
        string_filed = %w[
          home_number
          comment
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

        @regular_donations = RegularDonation.where([query_string, *query_array])
      elsif date&.match?(%r{\d{4}/\d{1,2}})
        year, month = date.split('/').map(&:to_i)

        begin_date = Date.civil(year, month, 1)
        end_date = Date.civil(year, month, -1)

        @regular_donations = RegularDonation.where(donation_at: begin_date..end_date)
      else
        @regular_donations = RegularDonation.all
      end

      @regular_donations = @regular_donations
                           .select(*%w[
                                     id
                                     home_number
                                     donation_at donation_amount
                                     comment
                                   ])

      render json: @regular_donations, status: :ok
    end

    # GET /regular_donations/{id}
    def show
      authorize! :read, @regular_donation
      render json: @regular_donation, status: :ok
    end

    # POST /regular_donations
    def create
      authorize! :create, RegularDonation

      create_params = regular_donation_params.to_h

      @regular_donation = RegularDonation.new(create_params)
      if @regular_donation.save
        render json: @regular_donation, status: :created
      else
        render json: { errors: @regular_donation.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /regular_donations/{id}
    def update
      authorize! :update, @regular_donation

      update_params = regular_donation_params.to_h

      return if @regular_donation.update(update_params)

      render json: { errors: @regular_donation.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /regular_donations/{id}
    def destroy
      authorize! :destroy, @regular_donation
      @regular_donation.destroy
    end

    def monthly_report
      # authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(%r{\d{4}/\d{1,2}})

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

    def yearly_report
      # authorize! :read, RegularDonation

      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      require 'axlsx'
      render json: { errors: 'Invalid date' }, status: :bad_request unless date&.match?(/\d{4}/)

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
        render json: every_monthly_report, status: :ok
      else
        send_data(p.to_stream.read, filename: "每月_#{year}教友奉獻明細表.xlsx",
                                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    private

    # @param [Integer] year
    # @return [Array]
    def get_yearly_report_array(year)
      all_month_str = (1..12).to_a.map { |e| "#{e}月" }
      row_hash, col_hash, yearly_report_data = report_data_init(all_month_str, '戶年度奉獻總計')

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
      row_hash, col_hash, results = report_data_init(all_sunday_str, summation_str)

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

    def report_data_init(filling_str, summation_str)
      all_household = Household.where('guest != true').order('home_number')
      all_home_number = all_household.map { |e| e['home_number'] }
      home_number_index = all_home_number.each_index.to_a.map { |i| i + 1 }

      all_col_name = ['家號', '姓名', *filling_str, summation_str]
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

    def find_regular_donation
      @regular_donation = RegularDonation.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Regular Donation not found' }, status: :not_found
    end

    def regular_donation_params
      params.permit(
        *%i[
          home_number
          donation_at donation_amount
          comment
        ]
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
