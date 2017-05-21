class CreateEditions < ActiveRecord::Migration[5.1]
  def change
    create_table :editions do |t|
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.integer :multiplier
      t.references :tournament, foreign_key: true

      t.timestamps
    end
  end
end
