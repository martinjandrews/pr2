class AddForeignKeysAndNotNullConstraints < ActiveRecord::Migration[7.2]
  def change
    change_column_null :editions, :tournament_id, false
    change_column_null :placings, :edition_id, false
    change_column_null :placings, :player_id, false
  end
end
