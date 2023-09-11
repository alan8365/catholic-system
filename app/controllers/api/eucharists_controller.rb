# frozen_string_literal: true

module Api
  # Eucharists controller
  class EucharistsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request
    before_action :find_eucharist, except: %i[create index]

    # GET /eucharists
    # @return [nil]
    def index
      authorize! :read, Eucharist
      query = params[:any_field]

      @eucharists = if query
                      string_filed = %w[
                        eucharist_location godfather godmother presbyter comment
                      ]

                      query_string = string_filed.join(" like ? or \n")
                      query_string += ' like ?'

                      query_array = string_filed.map { |_| "%#{query}%" }.compact

                      Eucharist.where([query_string, *query_array])
                    else
                      Eucharist.all
                    end

      @eucharists = @eucharists.select(*%w[
                                         id
                                         eucharist_at eucharist_location
                                         godfather godmother
                                         godfather_id godmother_id
                                         presbyter presbyter_id
                                         parishioner_id
                                         comment
                                       ])

      render json: @eucharists,
             include: { parishioner: { include: :baptism } },
             methods: %i[serial_number],
             status: :ok
    end

    # GET /eucharists/{id}
    def show
      authorize! :read, @eucharist
      render json: @eucharist,
             include: { parishioner: { include: :baptism } },
             methods: %i[serial_number],
             status: :ok
    end

    # POST /eucharists
    def create
      authorize! :create, Eucharist

      @eucharist = Eucharist.new(eucharist_params)
      if @eucharist.save
        render json: @eucharist, status: :created
      else
        render json: { errors: @eucharist.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /eucharists/{id}
    def update
      authorize! :update, @eucharist

      return if @eucharist.update(eucharist_params)

      render json: { errors: @eucharist.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /eucharists/{id}
    def destroy
      authorize! :destroy, @eucharist

      @eucharist.destroy
    end

    private

    def find_eucharist
      @eucharist = Eucharist.find_by_parishioner_id!(params[:_parishioner_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Eucharist not found' }, status: :not_found
    end

    def eucharist_params
      params.permit(%i[
                      eucharist_at eucharist_location
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
