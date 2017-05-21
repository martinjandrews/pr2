class CreatePlacings < ActiveRecord::Migration[5.1]
  def change
    create_table :placings do |t|
      t.integer :position
      t.references :edition, foreign_key: true
      t.references :player, foreign_key: true

      t.timestamps
    end
  end
end
