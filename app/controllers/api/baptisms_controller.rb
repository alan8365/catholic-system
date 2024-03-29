# frozen_string_literal: true

module Api
  # CRUD for baptism
  class BaptismsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request
    before_action :find_baptism, except: %i[create index]

    # GET /baptisms
    # @return [nil]
    def index
      authorize! :read, Baptism
      query = params[:any_field]
      date = params[:date]

      page = if params[:page].present?
               params[:page]
             else
               '1'
             end
      per_page = if params[:per_page].present?
                   params[:per_page]
                 else
                   '10'
                 end

      page = page.to_i
      per_page = per_page.to_i

      non_page = ActiveRecord::Type::Boolean.new.cast(params[:non_page])

      include_models = %i[parishioner]

      @baptisms = if query.present?
                    string_filed = %w[
                      (last_name||first_name)
                      baptized_location christian_name
                      godfather godmother presbyter
                      baptisms.comment
                    ]

                    query_string = string_filed.join(" like ? or \n")
                    query_string += ' like ?'

                    query_array = string_filed.map { |_| "%#{query}%" }.compact

                    Baptism.includes(include_models).joins(:parishioner).where([query_string, *query_array])
                  else
                    Baptism.includes(include_models).all
                  end

      if date&.match?(/\d{4}/)
        year = date.to_i
        date_range = Date.civil(year, 1, 1)..Date.civil(year, 12, -1)

        @baptisms = @baptisms.where(baptized_at: date_range)
      end

      @baptisms = @baptisms.select(*%w[
                                     id
                                     baptized_at baptized_location christian_name
                                     godfather godmother
                                     godfather_id godmother_id
                                     presbyter presbyter_id
                                     parishioner_id
                                     comment
                                   ])

      if non_page
        result = @baptisms
        total_page = 1
      else
        result = @baptisms.paginate(page:, per_page:)
        total_page = result.total_pages
      end
      result = result
               .as_json(
                 include: include_models,
                 methods: %i[serial_number]
               )

      render json: {
               data: result,
               total_page:
             },
             status: :ok
    end

    # GET /baptisms/{id}
    def show
      authorize! :read, @baptism
      render json: @baptism,
             include: %i[parishioner],
             methods: %i[serial_number],
             status: :ok
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
      render json: { errors: I18n.t('baptism_not_found') }, status: :not_found
    end

    def baptism_params
      params.permit(%i[
                      baptized_at baptized_location christian_name
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
