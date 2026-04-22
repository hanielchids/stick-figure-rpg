class CreatePlayerStats < ActiveRecord::Migration[8.1]
  def change
    create_table :player_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :kills
      t.integer :deaths
      t.integer :wins
      t.integer :losses
      t.integer :total_xp
      t.integer :matches_played
      t.integer :time_played_sec
      t.integer :best_kill_streak

      t.timestamps
    end
  end
end
