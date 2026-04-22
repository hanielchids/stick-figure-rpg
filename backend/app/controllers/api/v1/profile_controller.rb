class Api::V1::ProfileController < ApplicationController
  before_action :authenticate!

  def show
    render json: {
      user: {
        id: current_user.id,
        username: current_user.username,
        elo_rating: current_user.elo_rating,
        level: current_user.level,
        xp_current: current_user.xp_current
      },
      stats: stats_json(current_user.player_stat),
      loadout: loadout_json(current_user.loadout)
    }
  end

  def update_loadout
    loadout = current_user.loadout
    if loadout.update(loadout_params)
      render json: { loadout: loadout_json(loadout) }
    else
      render json: { errors: loadout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def stats
    user = User.find(params[:id])
    render json: { stats: stats_json(user.player_stat) }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Player not found" }, status: :not_found
  end

  private

  def loadout_params
    params.permit(:preferred_weapon, :skin_id, :crosshair_style)
  end

  def stats_json(stat)
    return {} unless stat
    {
      kills: stat.kills,
      deaths: stat.deaths,
      kd_ratio: stat.kd_ratio,
      wins: stat.wins,
      losses: stat.losses,
      total_xp: stat.total_xp,
      matches_played: stat.matches_played,
      time_played_sec: stat.time_played_sec,
      best_kill_streak: stat.best_kill_streak
    }
  end

  def loadout_json(loadout)
    return {} unless loadout
    {
      preferred_weapon: loadout.preferred_weapon,
      skin_id: loadout.skin_id,
      crosshair_style: loadout.crosshair_style
    }
  end
end
