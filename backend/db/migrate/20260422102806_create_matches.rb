class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.string :map
      t.string :mode
      t.integer :duration_sec
      t.string :state
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
