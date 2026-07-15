class RenameMultiplierToTierOnEditions < ActiveRecord::Migration[7.2]
  def up
    rename_column :editions, :multiplier, :tier
    change_column :editions, :tier, :integer
  end

  def down
    change_column :editions, :tier, :decimal
    rename_column :editions, :tier, :multiplier
  end
end
