# frozen_string_literal: true

module Api
  # CRUD for baptism
  class BaptismsController < ApplicationController
    before_action :authorize_request
    before_action :find_baptism, except: %i[create index]

    # GET /baptisms
    # @todo change the
    # @return [nil]
    def index
      authorize! :read, Baptism
      @query = params[:any_field]

      @baptisms = if @query
                    # TODO: change to full text search
                    Baptism
                      .where(["
                            baptized_location like ?  or
                            christian_name like ? or
                            godfather like ? or
                            godmother like ? or
                            presbyter like ?",
                              "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
                  else
                    Baptism.all
                  end

      @baptisms = @baptisms.select(*%w[
                                     baptized_at baptized_location christian_name
                                     godfather godmother
                                     godfather_id godmother_id
                                     presbyter presbyter_id
                                     parishioner_id
                                   ])
                           .as_json(except: :id)

      render json: @baptisms, status: :ok
    end

    # GET /baptisms/{id}
    def show
      authorize! :read, @baptism
      render json: @baptism, include: %i[parishioner], status: :ok
    end

    # POST /baptisms
    def create
      authorize! :create, Baptism

      @baptism = Baptism.new(baptism_params)
      if @baptism.save
        render json: @baptism, status: :created
      else
        render json: { errors: @baptism.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /baptisms/{id}
    def update
      authorize! :update, @baptism

      # TODO: update associations

      update_params = baptism_params.to_h
      if update_params.include?('parishioner_id')
        @parishioner = Parishioner.find_by_id(update_params['parishioner_id'])

        update_params.delete('parishioner_id')
      end

      return if @baptism.update(baptism_params)

      render json: { errors: @baptism.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /baptisms/{id}
    def destroy
      authorize! :destroy, @baptism

      @baptism.destroy
    end

    private

    def find_baptism
      @baptism = Baptism.find_by_parishioner_id!(params[:_parishioner_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Baptism not found' }, status: :not_found
    end

    def baptism_params
      params.permit(%i[
                      baptized_at baptized_location christian_name
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
