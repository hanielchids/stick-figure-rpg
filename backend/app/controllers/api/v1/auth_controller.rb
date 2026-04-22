class Api::V1::AuthController < ApplicationController
  def signup
    user = User.new(
      username: params[:username],
      email: params[:email],
      password: params[:password],
      elo_rating: 1000,
      level: 1,
      xp_current: 0
    )

    if user.save
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      user.update(last_login_at: Time.current)
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  def user_json(user)
    {
      id: user.id,
      username: user.username,
      email: user.email,
      elo_rating: user.elo_rating,
      level: user.level,
      xp_current: user.xp_current
    }
  end
end
