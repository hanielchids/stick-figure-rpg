class CreateLoadouts < ActiveRecord::Migration[8.1]
  def change
    create_table :loadouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :preferred_weapon
      t.string :skin_id
      t.string :crosshair_style

      t.timestamps
    end
  end
end
