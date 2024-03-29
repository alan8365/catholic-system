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

      include_model = {
        parishioner: :baptism
      }
      include_model_json = {
        parishioner: {
          include: :baptism
        }
      }

      @eucharists = if query
                      string_filed = %w[
                        (last_name||first_name)
                        eucharist_location
                        godfather godmother presbyter
                        eucharists.comment
                      ]

                      query_string = string_filed.join(" like ? or \n")
                      query_string += ' like ?'

                      query_array = string_filed.map { |_| "%#{query}%" }.compact

                      Eucharist.includes(include_model).joins(:parishioner).where([query_string, *query_array])
                    else
                      Eucharist.includes(include_model).all
                    end

      if date&.match?(/\d{4}/)
        year = date.to_i
        date_range = Date.civil(year, 1, 1)..Date.civil(year, 12, -1)

        @eucharists = @eucharists.where(eucharist_at: date_range)
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

      if non_page
        result = @eucharists
        total_page = 1
      else
        result = @eucharists.paginate(page:, per_page:)
        total_page = result.total_pages
      end

      result = result
               .as_json(
                 include: include_model_json,
                 methods: %i[serial_number]
               )

      render json: {
               data: result,
               total_page:
             },
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
      render json: { errors: I18n.t('eucharist_not_found') }, status: :not_found
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
