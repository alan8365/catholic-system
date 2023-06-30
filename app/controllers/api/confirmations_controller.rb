# frozen_string_literal: true

module Api
  # Confirmations controller
  class ConfirmationsController < ApplicationController
    before_action :authorize_request
    before_action :find_confirmation, except: %i[create index]

    # GET /confirmations
    # @return [nil]
    def index
      authorize! :read, Confirmation
      query = params[:any_field]

      @confirmations = if query
                         string_filed = %w[
                           confirmed_location christian_name godfather godmother presbyter comment
                         ]

                         query_string = string_filed.join(" like ? or \n")
                         query_string += ' like ?'

                         query_array = string_filed.map { |_| "%#{query}%" }.compact
                         Confirmation.where([query_string, *query_array])
                       else
                         Confirmation.all
                       end

      @confirmations = @confirmations.select(*%w[
                                               id
                                               confirmed_at confirmed_location christian_name
                                               godfather godmother
                                               godfather_id godmother_id
                                               presbyter presbyter_id
                                               parishioner_id
                                               comment
                                             ])

      render json: @confirmations, include: %i[parishioner], status: :ok
    end

    # GET /confirmations/{id}
    def show
      authorize! :read, @confirmation
      render json: @confirmation, include: %i[parishioner], status: :ok
    end

    # POST /confirmations
    def create
      authorize! :create, Confirmation

      @confirmation = Confirmation.new(confirmation_params)
      if @confirmation.save
        render json: @confirmation, status: :created
      else
        render json: { errors: @confirmation.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /confirmations/{id}
    def update
      authorize! :update, @confirmation

      return if @confirmation.update(confirmation_params)

      render json: { errors: @confirmation.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /confirmations/{id}
    def destroy
      authorize! :destroy, @confirmation

      @confirmation.destroy
    end

    private

    def find_confirmation
      @confirmation = Confirmation.find_by_parishioner_id!(params[:_parishioner_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Confirmation not found' }, status: :not_found
    end

    def confirmation_params
      params.permit(%i[
                      confirmed_at confirmed_location christian_name
                      godfather godmother
                      godfather_id godmother_id
                      presbyter presbyter_id
                      parishioner_id
                      comment
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
