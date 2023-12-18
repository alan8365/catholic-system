# frozen_string_literal: true

module Api
  class UsersController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request # , except: :index
    before_action :find_user, except: %i[create index]

    # GET /users
    def index
      authorize! :read, User
      @query = params[:any_field]

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

      @users = if @query
                 User
                   .where(['name like ? or username like ? or comment like ?', "%#{@query}%", "%#{@query}%",
                           "%#{@query}%"])
               else
                 User.all
               end

      if non_page
        result = @users
        total_page = 1
      else
        result = @users.paginate(page:, per_page:)
        total_page = result.total_pages
      end

      result = result
               .select(*%w[username name comment is_admin is_modulator])
               .as_json(except: :id)

      render json: {
               data: result,
               total_page:
             },
             status: :ok
    end

    # GET /users/{username}
    def show
      authorize! :read, @user
      render json: @user, status: :ok
    end

    # POST /users
    def create
      authorize! :create, User

      @user = User.new(user_params)
      if @user.save
        render json: @user, status: :created
      else
        render json: { errors: @user.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /users/{username}
    # TODO change password
    def update
      authorize! :update, @user
      return if @user.update(user_params)

      render json: { errors: @user.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /users/{username}
    def destroy
      authorize! :destroy, @user

      @user.destroy
    end

    private

    def find_user
      @user = User.find_by_username!(params[:_username])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('user_not_found') }, status: :not_found
    end

    def user_params
      params.permit(
        :name, :username, :comment, :password, :is_admin, :is_modulator
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
