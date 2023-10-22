# frozen_string_literal: true

# require 'jwt'

module RequestSpecHelper
  def json
    JSON.parse(response.body)
  end

  def auth_header(user)
    # get '/users/confirm', params: {token: user.confirmation_token}
    post '/auth/login', params: { email: user.email, password: user.password }
    # return json['auth_token']
    # payload = {user_id: user.id}
    "Bearer #{json['token']}"
  end
end
