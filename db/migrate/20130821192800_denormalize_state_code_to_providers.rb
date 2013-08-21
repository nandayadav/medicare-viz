class DenormalizeStateCodeToProviders < ActiveRecord::Migration
  def up
    add_column :providers, :state_code, :string
  end

  def down
  end
end
