# frozen_string_literal: true

module Api
  # CRUD for baptism
  class BaptismController < ApplicationController
    before_action :authorize_request, except: :picture
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
                            baptist like ?",
                              "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
                  else
                    Baptism.all
                  end

      @baptisms = @baptisms
                  .select(*%w[
                            baptized_at baptized_location christian_name
                            godfather godmother
                            baptist
                            baptized_person
                          ])
                  .as_json(except: :id)

      render json: @baptisms, status: :ok
    end

    # GET /baptisms/{id}
    def show
      authorize! :read, @baptism
      render json: @baptism, status: :ok
    end

    def picture
      if @baptism.picture.attached?
        send_file @baptism.picture_url, type: 'image/png', disposition: 'inline'
      else
        head :not_found
      end
    end

    # POST /baptisms
    # TODO upload image
    def create
      authorize! :create, Baptism

      create_params = baptism_params.to_h
      create_params.delete('picture') if 'picture'.in?(create_params.keys) && (create_params['picture'].is_a? String)

      @baptism = Baptism.new(create_params)
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
      @baptism = Baptism.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Baptism not found' }, status: :not_found
    end

    def baptism_params
      params.permit(%i[
                      baptized_at baptized_location christian_name
                      godfather godmother
                      baptist
                      baptized_person
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
