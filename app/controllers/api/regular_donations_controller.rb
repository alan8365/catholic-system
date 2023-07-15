# frozen_string_literal: true

module Api
  class RegularDonationsController < ApplicationController
    before_action :authorize_request, except: %i[monthly_report]
    before_action :find_regular_donation, except: %i[create index monthly_report]

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

      require 'axlsx'
      if date&.match?(%r{\d{4}/\d{1,2}})
        # Date process
        year, month = date.split('/').map(&:to_i)
        all_col_name, results = get_monthly_report_array(year, month)

        p = Axlsx::Package.new
        wb = p.workbook

        wb.add_worksheet(name: 'Basic Worksheet') do |sheet|
          sheet.add_row all_col_name

          results.each do |result|
            # Parishioner summation added
            result[-1] = result[2..].sum(&:to_i)

            sheet.add_row result
          end

          # Merge cell of summation
          (-3..-1).each do |i|
            sheet.merge_cells sheet.rows[i].cells[(0..1)]
          end
        end

        if is_test
          render json: results, status: :ok
        else
          send_data(p.to_stream.read, filename: "#{date}主日奉獻統計資料.xlsx",
                                      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        end
      else
        render json: { errors: 'Invalid date' }, status: :bad_request
      end
    end

    def yearly_report
      date = params[:date]
      is_test = ActiveModel::Type::Boolean.new.cast(params[:test])

      require 'axlsx'
      if date&.match?(/\d{4}/)

        if is_test
          render json: results, status: :ok
        else
          # send_data(p.to_stream.read, filename: 'example.xlsx',
          #           type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        end
      else
        render json: { errors: 'Invalid date' }, status: :bad_request
      end
    end

    private

    # @param [Integer] year
    # @param [Integer] month
    def get_monthly_report_array(year, month)
      all_sunday, all_sunday_str = get_all_sunday_in_month(month, year)

      # Results array process
      all_household = Household.where('guest != true').order('home_number')
      all_home_number = all_household.map { |e| e['home_number'] }
      home_number_index = all_home_number.each_index.to_a

      all_col_name = ['家號', '姓名', *all_sunday_str, "#{month}月份總計"]
      col_name_index = all_col_name.each_index.to_a

      row_hash = Hash[all_home_number.zip(home_number_index)]
      col_hash = Hash[all_col_name.zip(col_name_index)]

      results = Array.new(row_hash.size + 3) { Array.new(col_hash.size) }

      all_household.each do |household|
        home_number = household['home_number']
        head_of_household = household.head_of_household
        name = head_of_household&.name

        row_index = row_hash[home_number]
        results[row_index][0] = home_number
        results[row_index][1] = name
      end

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

      [all_col_name, results]
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
