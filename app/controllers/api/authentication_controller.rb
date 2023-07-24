# frozen_string_literal: true

module Api
  # Controller for JWT auth
  class AuthenticationController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: :login

    # POST /auth/login
    def login
      @user = User.find_by_username(params[:username])
      if @user&.authenticate(params[:password])
        time = 4.weeks.from_now
        token = JsonWebToken.encode(
          user_id: @user.id,
          username: @user.username,
          is_admin: @user.is_admin,
          is_modulator: @user.is_modulator
        )
        render json: { token:,
                       # exp: time.strftime('%m-%d-%Y %H:%M'),
                       username: @user.username }, status: :ok
      else
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end

    private

    def login_params
      params.permit(:email, :password)
    end
  end
end
