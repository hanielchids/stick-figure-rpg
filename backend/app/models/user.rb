class User < ApplicationRecord
  has_secure_password

  has_one :player_stat, dependent: :destroy
  has_one :loadout, dependent: :destroy
  has_many :match_participants, dependent: :nullify

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_defaults

  private

  def create_defaults
    create_player_stat!(
      kills: 0, deaths: 0, wins: 0, losses: 0,
      total_xp: 0, matches_played: 0, time_played_sec: 0, best_kill_streak: 0
    )
    create_loadout!(preferred_weapon: "Pistol", skin_id: "default", crosshair_style: "cross")
  end
end
