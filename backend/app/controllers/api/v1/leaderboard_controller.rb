class Api::V1::LeaderboardController < ApplicationController
  def index
    scope = params[:scope] || "kills"
    page = (params[:page] || 1).to_i
    per_page = 20

    rankings = PlayerStat.joins(:user)
      .select("player_stats.*, users.username")
      .order("player_stats.#{safe_scope(scope)} DESC")
      .offset((page - 1) * per_page)
      .limit(per_page)

    render json: {
      rankings: rankings.map.with_index((page - 1) * per_page + 1) do |stat, rank|
        {
          rank: rank,
          username: stat.username,
          kills: stat.kills,
          deaths: stat.deaths,
          kd_ratio: stat.kd_ratio,
          wins: stat.wins,
          matches_played: stat.matches_played,
          total_xp: stat.total_xp
        }
      end,
      page: page,
      scope: scope
    }
  end

  private

  def safe_scope(scope)
    %w[kills wins total_xp matches_played].include?(scope) ? scope : "kills"
  end
end
