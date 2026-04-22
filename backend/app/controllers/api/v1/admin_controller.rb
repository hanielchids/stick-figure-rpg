class Api::V1::AdminController < ApplicationController
  def stats
    render json: {
      total_users: User.count,
      total_matches: Match.count,
      matches_today: Match.where("created_at > ?", Time.current.beginning_of_day).count,
      active_users_today: User.where("last_login_at > ?", Time.current.beginning_of_day).count,
      total_kills: PlayerStat.sum(:kills),
      total_time_played_hours: (PlayerStat.sum(:time_played_sec) / 3600.0).round(1),
      top_player: User.joins(:player_stat).order("player_stats.kills DESC").first&.username,
      avg_match_duration_sec: Match.where(state: "finished").average(:duration_sec)&.round(0)
    }
  end
end
