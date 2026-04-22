class ApplicationController < ActionController::API
  private

  def authenticate!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = JwtService.decode(token)

    if payload
      @current_user = User.find_by(id: payload[:user_id])
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
