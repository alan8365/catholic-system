# frozen_string_literal: true

module Api
  # Eucharists controller
  class EucharistsController < ApplicationController
    before_action :authorize_request
    before_action :find_eucharist, except: %i[create index]

    # GET /eucharists
    # @return [nil]
    def index
      authorize! :read, Eucharist
      @query = params[:any_field]

      @eucharists = if @query
                      # TODO: change to full text search
                      Eucharist
                        .where(["
                            eucharist_location like ? or
                            christian_name like ? or
                            godfather like ? or
                            godmother like ? or
                            presbyter like ?",
                                "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
                    else
                      Eucharist.all
                    end

      @eucharists = @eucharists.select(*%w[
                                         id
                                         eucharist_at eucharist_location christian_name
                                         godfather godmother
                                         godfather_id godmother_id
                                         presbyter presbyter_id
                                         parishioner_id
                                       ])

      render json: @eucharists, include: %i[parishioner], status: :ok
    end

    # GET /eucharists/{id}
    def show
      authorize! :read, @eucharist
      render json: @eucharist, include: %i[parishioner], status: :ok
    end

    # POST /eucharists
    # TODO upload image
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

      # TODO: update associations

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
                      eucharist_at eucharist_location christian_name
                      godfather godmother
                      godfather_id godmother_id
                      presbyter presbyter_id
                      parishioner_id
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
