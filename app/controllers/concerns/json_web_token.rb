# frozen_string_literal: true

require 'jwt'
##
# Json Web token encoder and decoder
#
module JsonWebToken
  extend ActiveSupport::Concern
  SECRET_KEY = Rails.application.secret_key_base

  def jwt_encode(payload)
    JWT.encode(payload, SECRET_KEY)
  end

  def jwt_decode(token)
    decoded = JWT.decode(token, SECRET_KEY)
    HashWithIndifferentAccess.new decoded.first
  end
end
