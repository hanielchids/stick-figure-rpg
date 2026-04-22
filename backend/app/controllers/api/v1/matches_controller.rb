class Api::V1::MatchesController < ApplicationController
  # Match results are posted by the game server, authenticated via server key
  def create
    match = Match.create!(
      map: params[:map],
      mode: params[:mode],
      duration_sec: params[:duration_sec],
      state: "finished",
      started_at: Time.current - params[:duration_sec].to_i.seconds,
      ended_at: Time.current
    )

    (params[:players] || []).each do |player_data|
      participant = match.match_participants.create!(
        user_id: player_data[:user_id],
        bot_name: player_data[:bot_name],
        kills: player_data[:kills] || 0,
        deaths: player_data[:deaths] || 0,
        damage_dealt: player_data[:damage_dealt] || 0,
        damage_taken: player_data[:damage_taken] || 0,
        team: player_data[:team],
        placement: player_data[:placement] || 0,
        xp_earned: player_data[:xp_earned] || 0
      )

      # Update player stats if this was a real player
      if participant.user_id.present?
        stat = participant.user.player_stat
        stat.increment!(:kills, participant.kills)
        stat.increment!(:deaths, participant.deaths)
        stat.increment!(:matches_played)
        stat.increment!(:total_xp, participant.xp_earned)
        stat.increment!(:time_played_sec, match.duration_sec || 0)

        if participant.placement == 1
          stat.increment!(:wins)
        else
          stat.increment!(:losses)
        end

        # Update user XP and level
        user = participant.user
        user.increment!(:xp_current, participant.xp_earned)
        while user.xp_current >= xp_for_level(user.level + 1)
          user.update!(level: user.level + 1)
        end
      end
    end

    render json: { match_id: match.id }, status: :created
  end

  private

  def xp_for_level(level)
    level * 100  # Simple linear progression
  end
end
