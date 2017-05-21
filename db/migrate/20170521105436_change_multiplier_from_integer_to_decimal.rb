class ChangeMultiplierFromIntegerToDecimal < ActiveRecord::Migration[5.1]
  def change
    change_column :editions, :multiplier, :decimal
  end
end
