# frozen_string_literal: true

module Api
  class ParishionersController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[picture]
    before_action :find_parishioner, except: %i[create index]

    # GET /parishioners
    def index
      authorize! :read, Parishioner
      query = params[:any_field]
      is_archive = params[:is_archive]

      if query
        string_filed = %w[
          name home_number gender address
          father mother
          nationality profession company_name
          home_phone mobile_phone
          original_parish destination_parish
          move_out_reason
          comment
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

        @parishioners = Parishioner.where([query_string, *query_array])
      else
        @parishioners = Parishioner.all
      end

      @parishioners = if is_archive == 'true'
                        @parishioners.where('move_out_date is not null')
                      else
                        @parishioners.where('move_out_date is null')
                      end

      @parishioners = @parishioners.select(*%w[
                                             id
                                             name gender birth_at postal_code address home_number
                                             father mother father_id mother_id
                                             home_phone mobile_phone nationality
                                             profession company_name comment
                                             move_in_date original_parish
                                             move_out_date move_out_reason destination_parish
                                           ])

      render json: @parishioners,
             include: %i[
               mother_instance father_instance
               child_for_mother child_for_father
               baptism confirmation eucharist
               wife husband
             ],
             methods: %i[children sibling],
             status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner

      render json: @parishioner,
             include: %i[
               mother_instance father_instance
               child_for_mother child_for_father
               baptism confirmation eucharist
               wife husband
             ], status: :ok
    end

    def picture
      if @parishioner.picture.attached?
        send_file @parishioner.picture_url, type: 'image/png', disposition: 'inline'
      else
        head :not_found
      end
    end

    # POST /parishioners
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
      update_params.delete('picture') if 'picture'.in?(update_params.keys) && (update_params['picture'].is_a? String)

      if update_params.include?('father_id') && !update_params['father_id'].empty?
        father_id = update_params['father_id']
        father = Parishioner.find_by_id(father_id)

        @parishioner.father_instance = father
        @parishioner.father = father.name if father

        update_params.delete('father_id')
        update_params.delete('father')
      end

      if update_params.include?('mother_id') && !update_params['mother_id'].empty?
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
                      father mother father_id mother_id
                      home_phone mobile_phone nationality
                      profession company_name comment
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
