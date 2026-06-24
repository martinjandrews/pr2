class AddForeignKeysAndNotNullConstraints < ActiveRecord::Migration[7.2]
  def change
    change_column_null :editions, :tournament_id, false
    change_column_null :placings, :edition_id, false
    change_column_null :placings, :player_id, false

    add_foreign_key :editions, :tournaments
    add_foreign_key :placings, :editions
    add_foreign_key :placings, :players
  end
end
