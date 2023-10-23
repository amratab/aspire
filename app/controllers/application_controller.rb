class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include JsonWebToken

  before_action :authenticate_request

  protected

  def respond_with_not_found(message)
    render json: { errors: message },
           status: :not_found
  end

  private

  # gets the last token from authorization header
  # and decodes it to get user_id
  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    decoded = jwt_decode(header)
    @current_user = User.find(decoded[:user_id])
  end
end
