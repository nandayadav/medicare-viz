class AddWeightedCols < ActiveRecord::Migration
  def up
    add_column :diagnostic_related_groups, :weighted_mean_charges, :float
    add_column :diagnostic_related_groups, :weighted_mean_payments, :float
  end

  def down
    remove_column :diagnostic_related_groups, :weighted_mean_payments
    remove_column :diagnostic_related_groups, :weighted_mean_charges
  end
end
