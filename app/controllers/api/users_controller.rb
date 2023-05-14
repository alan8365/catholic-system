module Api
  class UsersController < ApplicationController
    before_action :authorize_request # , except: :index
    before_action :find_user, except: %i[create index]

    # GET /users
    # @todo change the
    def index
      @users = User.all
      authorize! :read, User
      render json: @users, status: :ok
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
      unless @user.update(user_params)
        render json: { errors: @user.errors.full_messages },
               status: :unprocessable_entity
      end
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
      render json: { errors: 'User not found' }, status: :not_found
    end

    def user_params
      params.permit(
        :name, :username, :password, :is_admin, :is_modulator
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end