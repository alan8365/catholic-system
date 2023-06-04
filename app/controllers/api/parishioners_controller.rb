# frozen_string_literal: true

module Api
  class ParishionersController < ApplicationController
    before_action :authorize_request, except: :picture
    before_action :find_parishioner, except: %i[create index]

    # GET /parishioners
    # @todo change the
    def index
      authorize! :read, Parishioner
      @query = params[:any_field]

      if @query
        # TODO: change to full text search

        @parishioners = Parishioner
                        .where(["
                            name like ?  or
                            comment like ? or
                            father like ? or
                            mother like ? or
                            spouse like ?",
                                "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
      else
        @parishioners = Parishioner.all
      end

      @parishioners = @parishioners
                      .select(*%w[
                                name gender birth_at postal_code address photo_url
                                father mother spouse father_id mother_id spouse_id
                                home_phone mobile_phone nationality
                                profession company_name comment
                              ])
                      .as_json(except: :id)

      render json: @parishioners, status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner
      render json: @parishioner, status: :ok
    end

    def picture
      if @parishioner.picture.attached?
        send_file @parishioner.picture_url, type: 'image/png', disposition: 'inline'
      else
        head :not_found
      end
    end

    # POST /parishioners
    # TODO upload image
    def create
      authorize! :create, Parishioner

      create_params = parishioner_params.to_h
      create_params.delete('picture') if 'picture'.in?(create_params.keys) && (create_params['picture'].is_a? String)

      @parishioner = Parishioner.new(create_params)
      if @parishioner.save
        render json: @parishioner, status: :created
      else
        render json: { errors: @parishioner.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /parishioners/{id}
    def update
      authorize! :update, @parishioner
      return if @parishioner.update(parishioner_params)

      render json: { errors: @parishioner.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /parishioners/{id}
    def destroy
      authorize! :destroy, @parishioner

      @parishioner.destroy
    end

    private

    def find_parishioner
      @parishioner = Parishioner.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Parishioner not found' }, status: :not_found
    end

    def parishioner_params
      params.permit(%i[
                      name gender birth_at postal_code address photo_url
                      father mother spouse father_id mother_id spouse_id
                      home_phone mobile_phone nationality
                      profession company_name comment
                      picture
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
