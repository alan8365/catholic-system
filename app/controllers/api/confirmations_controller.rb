# frozen_string_literal: true

module Api
  # Confirmations controller
  class ConfirmationsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request
    before_action :find_confirmation, except: %i[create index]

    # GET /confirmations
    # @return [nil]
    def index
      authorize! :read, Confirmation
      query = params[:any_field]
      date = params[:date]

      @confirmations = if query
                         string_filed = %w[
                           (last_name||first_name)
                           confirmed_location
                           godfather godmother presbyter
                           confirmations.comment
                         ]

                         query_string = string_filed.join(" like ? or \n")
                         query_string += ' like ?'

                         query_array = string_filed.map { |_| "%#{query}%" }.compact
                         Confirmation.joins(:parishioner).where([query_string, *query_array])
                       else
                         Confirmation.all
                       end

      if date&.match?(/\d{4}/)
        year = date.to_i
        date_range = Date.civil(year, 1, 1)..Date.civil(year, 12, -1)

        @confirmations = @confirmations.where(confirmed_at: date_range)
      end

      @confirmations = @confirmations.select(*%w[
                                               id
                                               confirmed_at confirmed_location
                                               godfather godmother
                                               godfather_id godmother_id
                                               presbyter presbyter_id
                                               parishioner_id
                                               comment
                                             ])

      render json: @confirmations,
             include: { parishioner: { include: :baptism } },
             methods: %i[serial_number],
             status: :ok
    end

    # GET /confirmations/{id}
    def show
      authorize! :read, @confirmation
      render json: @confirmation,
             include: { parishioner: { include: :baptism } },
             methods: %i[serial_number],
             status: :ok
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
      render json: { errors: I18n.t('confirmation_not_found') }, status: :not_found
    end

    def confirmation_params
      params.permit(%i[
                      confirmed_at confirmed_location
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
