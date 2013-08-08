class CreateStates < ActiveRecord::Migration
  def change
    create_table :states do |t|
      t.string          :name, :abbreviation
      t.timestamps
    end
    remove_column :providers, :referral_region
    remove_column :providers, :total_discharges
    remove_column :providers, :avg_covered_charges
    remove_column :providers, :avg_total_payments
    remove_column :providers, :diagnostic_related_group_id
    remove_column :providers, :state
    add_column :providers, :state_id, :integer
  end
end
