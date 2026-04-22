class PlayerStat < ApplicationRecord
  belongs_to :user

  def kd_ratio
    return 0.0 if deaths.zero?
    (kills.to_f / deaths).round(2)
  end
end
