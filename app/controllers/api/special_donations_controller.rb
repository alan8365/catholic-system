# frozen_string_literal: true

module Api
  class SpecialDonationsController < ApplicationController
    before_action :authorize_request, except: %i[]
    before_action :find_regular_donation, except: %i[create index]

    # GET /regular_donations
    def index
      authorize! :read, SpecialDonation
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

        @special_donations = SpecialDonation.where([query_string, *query_array])
      elsif date&.match?(%r{\d{4}/\d{1,2}})
        year, month = date.split('/').map(&:to_i)

        begin_date = Date.civil(year, month, 1)
        end_date = Date.civil(year, month, -1)

        @special_donations = SpecialDonation.where(donation_at: begin_date..end_date)
      else
        @special_donations = SpecialDonation.all
      end

      @special_donations = @special_donations
                           .select(*%w[
                                     id
                                     home_number event_id
                                     donation_at donation_amount
                                     receipt
                                     comment
                                   ])

      render json: @special_donations, include: { household: { include: :head_of_household } }, status: :ok
    end

    # GET /regular_donations/{id}
    def show
      authorize! :read, @regular_donation
      render json: @regular_donation, status: :ok
    end

    # POST /regular_donations
    def create
      authorize! :create, SpecialDonation

      create_params = regular_donation_params.to_h

      @regular_donation = SpecialDonation.new(create_params)
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

    private

    def find_regular_donation
      @regular_donation = SpecialDonation.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Regular Donation not found' }, status: :not_found
    end

    def regular_donation_params
      params.permit(
        *%i[
          event_id
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
