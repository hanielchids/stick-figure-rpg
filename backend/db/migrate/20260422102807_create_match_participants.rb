class CreateMatchParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :match_participants do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :bot_name
      t.integer :kills
      t.integer :deaths
      t.integer :damage_dealt
      t.integer :damage_taken
      t.integer :team
      t.integer :placement
      t.integer :xp_earned

      t.timestamps
    end
  end
end
