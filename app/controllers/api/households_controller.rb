# frozen_string_literal: true

module Api
  class HouseholdsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request
    before_action :find_household, except: %i[create index]

    # GET /households
    def index
      authorize! :read, Household
      query = params[:any_field]
      is_archive = params[:is_archive]

      if query
        string_filed = %w[
          home_number
          comment
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

        @households = Household.where([query_string, *query_array])
      else
        @households = Household.all
      end

      @households = if is_archive == 'true'
                      @households.where('is_archive' => true)
                    else
                      @households.where('is_archive' => false)
                    end

      @households = @households
                    .select(*%w[
                              home_number head_of_household
                              special guest is_archive
                              comment
                            ])

      render json: @households, include: %i[head_of_household parishioners], status: :ok
    end

    # GET /households/{home_number}
    def show
      authorize! :read, @household
      render json: @household, include: %i[head_of_household parishioners], status: :ok
    end

    # POST /households
    def create
      authorize! :create, Household

      create_params = household_params.to_h
      if 'head_of_household_id'.in? household_params.keys
        create_params['head_of_household'] = Parishioner.find_by_id(household_params['head_of_household_id'])
        create_params.delete('head_of_household_id')
      end

      @household = Household.new(create_params)
      if @household.save
        render json: @household, status: :created
      else
        render json: { errors: @household.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /households/{home_number}
    def update
      authorize! :update, @household

      update_params = household_params.to_h
      if 'head_of_household_id'.in?(update_params.keys)
        @household.head_of_household = Parishioner.find_by_id(update_params['head_of_household_id'])
        update_params.delete('head_of_household_id')
      end

      return if @household.update(update_params)

      render json: { errors: @household.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /households/{home_number}
    def destroy
      authorize! :destroy, @household
      @household.destroy
    end

    private

    def find_household
      @household = Household.find_by_home_number!(params[:_home_number])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('household_not_found') }, status: :not_found
    end

    def household_params
      params.permit(
        *%i[
          home_number
          head_of_household head_of_household_id
          special guest is_archive
          comment
        ]
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
