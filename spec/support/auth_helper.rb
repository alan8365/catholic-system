module AuthHelper
  def http_login
    token = 'SomeRandomToken'
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(token)
  end
end