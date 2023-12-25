# frozen_string_literal: true

module Api
  # CRUD for Marriages
  class MarriagesController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request
    before_action :find_marriage, except: %i[create index]

    # GET /marriages
    # @return [nil]
    def index
      authorize! :read, Marriage
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

      @marriages = if query
                     string_filed = %w[
                       marriage_location groom bride presbyter comment
                     ]

                     query_string = string_filed.join(" like ? or \n")
                     query_string += ' like ?'

                     query_array = string_filed.map { |_| "%#{query}%" }.compact

                     Marriage.where([query_string, *query_array])
                   else
                     Marriage.all
                   end

      if date&.match?(/\d{4}/)
        year = date.to_i
        date_range = Date.civil(year, 1, 1)..Date.civil(year, 12, -1)

        @marriages = @marriages.where(marriage_at: date_range)
      end

      @marriages = @marriages.select(*%w[
                                       id
                                       marriage_at marriage_location
                                       groom groom_id groom_birth_at groom_father groom_mother
                                       bride bride_id bride_birth_at bride_father bride_mother
                                       witness1 witness2
                                       presbyter presbyter_id
                                       comment
                                     ])
      if non_page
        result = @marriages
        total_page = 1
      else
        result = @marriages.paginate(page:, per_page:)
        total_page = result.total_pages
      end

      result = result
               .as_json(
                 methods: %i[serial_number]
               )

      render json: {
               data: result,
               total_page:
             },
             status: :ok
    end

    # GET /marriages/{id}
    def show
      authorize! :read, @marriage
      render json: @marriage,
             include: { groom_instance: { include: :baptism }, bride_instance: { include: :baptism } }, status: :ok
    end

    # POST /marriages
    def create
      authorize! :create, Marriage

      create_params = marriage_params.to_h
      @marriage = Marriage.new(create_params)
      if @marriage.save
        render json: @marriage, status: :created
      else
        render json: { errors: @marriage.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /marriages/{id}
    def update
      authorize! :update, @marriage

      return if @marriage.update(marriage_params)

      render json: { errors: @marriage.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /marriages/{id}
    def destroy
      authorize! :destroy, @marriage

      @marriage.destroy
    end

    private

    def find_marriage
      @marriage = Marriage.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('marriage_not_found') }, status: :not_found
    end

    def marriage_params
      params.permit(%i[
                      marriage_at marriage_location
                      groom groom_id groom_birth_at groom_father groom_mother
                      bride bride_id bride_birth_at bride_father bride_mother
                      witness1 witness2
                      presbyter presbyter_id
                      comment
                    ])
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
