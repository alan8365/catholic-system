# frozen_string_literal: true

module Api
  class HouseholdsController < ApplicationController
    before_action :authorize_request
    before_action :find_household, except: %i[create index]

    # GET /households
    def index
      authorize! :read, Household
      @query = params[:any_field]

      @households = if @query
                      Household
                        .where(['home_number like ?', "%#{@query}%"])
                    else
                      Household.all
                    end

      @households = @households
                    .select(*%w[home_number head_of_household])

      render json: @households, status: :ok
    end

    # GET /households/{home_number}
    def show
      authorize! :read, @household
      render json: @household, status: :ok
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
      return if @household.update(household_params)

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
      render json: { errors: 'Household not found' }, status: :not_found
    end

    def household_params
      params.permit(
        :home_number, :head_of_household, :head_of_household_id
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
