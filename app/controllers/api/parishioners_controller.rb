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
                            spouse like ? or
                            home_number like ? or
                            nationality like ? or
                            profession like ? or
                            company_name like ?
                          ",
                                  "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%",
                                  "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
      else
        @parishioners = Parishioner.all
      end

      @parishioners = @parishioners
                        .select(*%w[
                                  id
                                  name gender birth_at postal_code address home_number
                                  father mother spouse father_id mother_id spouse_id
                                  home_phone mobile_phone nationality
                                  profession company_name comment
                                  sibling_number children_number
                                  move_in_date original_parish
                                  move_out_date move_out_reason destination_parish
                                ])

      render json: @parishioners, include: %i[baptism confirmation eucharist], status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner

      render json: @parishioner, include: %i[spouse_instance mother_instance father_instance baptism confirmation eucharist], status: :ok
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

      update_params = parishioner_params.to_h
      if update_params.include?('spouse_id')
        spouse = Parishioner.find_by_id(update_params['spouse_id'])

        @parishioner.spouse_instance = spouse
        @parishioner.spouse = spouse.name if spouse

        update_params.delete('spouse_id')
        update_params.delete('spouse')
      end

      if update_params.include?('father_id')
        father = Parishioner.find_by_id(update_params['father_id'])

        @parishioner.father_instance = father
        @parishioner.father = father.name if father

        update_params.delete('father_id')
        update_params.delete('father')
      end

      if update_params.include?('mother_id')
        mother = Parishioner.find_by_id(update_params['mother_id'])

        @parishioner.mother_instance = mother
        @parishioner.mother = mother.name if mother

        update_params.delete('mother_id')
        update_params.delete('mother')
      end

      return if @parishioner.update(update_params)

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
                      name gender birth_at postal_code address home_number
                      father mother spouse father_id mother_id spouse_id
                      home_phone mobile_phone nationality
                      profession company_name comment
                      sibling_number children_number
                      move_in_date original_parish
                      move_out_date move_out_reason destination_parish
                      picture
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
