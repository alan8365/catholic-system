module Api
  class ParishionersController < ApplicationController
    before_action :authorize_request # , except: :index
    before_action :find_parishioner, except: %i[create index]

    # GET /users
    # @todo change the
    def index
      authorize! :read, User
      @query = params[:any_field]

      if @query
        @users = User
                   .where(["name like ? or username like ? or comment like ?", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
      else
        @users = User.all
      end

      @users = @users
                 .select(*%w[username name comment is_admin is_modulator])
                 .as_json(except: :id)

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

    def find_parishioner
      @parishioner = Parishioner.find_by_id!(params[:_username])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Parishioner not found' }, status: :not_found
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