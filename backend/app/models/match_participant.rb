class MatchParticipant < ApplicationRecord
  belongs_to :match
  belongs_to :user, optional: true
end
