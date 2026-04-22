class Match < ApplicationRecord
  has_many :match_participants, dependent: :destroy

  validates :map, presence: true
  validates :mode, presence: true
  validates :state, inclusion: { in: %w[in_progress finished abandoned] }
end
