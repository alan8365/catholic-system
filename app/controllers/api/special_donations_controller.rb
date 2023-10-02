# frozen_string_literal: true

module Api
  class SpecialDonationsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[]
    before_action :find_special_donation, except: %i[create index]

    # GET /special_donations
    def index
      authorize! :read, SpecialDonation

      query = params[:any_field] || ''
      date = params[:date] || ''
      event_id = params[:event_id] || ''

      @special_donations = SpecialDonation
                           .left_outer_joins(household: :head_of_household)
                           .select(%w[special_donations.* parishioners.last_name parishioners.first_name])

      unless event_id.empty?
        event_id = event_id.to_i

        @special_donations = @special_donations.where(event_id:)
      end

      if date&.match?(%r{\d{4}/\d{1,2}})
        year, month = date.split('/').map(&:to_i)

        begin_date = Date.civil(year, month, 1)
        end_date = Date.civil(year, month, -1)

        @special_donations = @special_donations.where(donation_at: begin_date..end_date)
      end

      unless query.empty?
        string_filed = %w[
          special_donations.home_number
          parishioners.last_name||parishioners.first_name
          special_donations.comment
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

        @special_donations = @special_donations.where([query_string, *query_array])
      end

      @special_donations = @special_donations
                           .select(*%w[
                                     id
                                     home_number event_id
                                     donation_at donation_amount
                                     receipt
                                     comment
                                   ])
      result = @special_donations.as_json.map do |e|
        e['name'] = ("#{e['last_name']}#{e['first_name']}" if e['last_name'] && e['first_name'])
        e
      end

      render json: result, status: :ok
    end

    # GET /special_donations/{id}
    def show
      authorize! :read, @special_donation
      render json: @special_donation, status: :ok
    end

    # POST /special_donations
    def create
      authorize! :create, SpecialDonation

      create_params = special_donation_params.to_h

      @special_donation = SpecialDonation.create(create_params)
      if @special_donation.save
        render json: @special_donation, status: :created
      else
        render json: { errors: @special_donation.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /special_donations/{id}
    def update
      authorize! :update, @special_donation

      update_params = special_donation_params.to_h

      return if @special_donation.update(update_params)

      render json: { errors: @special_donation.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /special_donations/{id}
    def destroy
      authorize! :destroy, @special_donation
      @special_donation.destroy
    end

    private

    def find_special_donation
      @special_donation = SpecialDonation.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Regular Donation not found' }, status: :not_found
    end

    def special_donation_params
      params.permit(
        *%i[
          event_id
          home_number
          receipt
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
