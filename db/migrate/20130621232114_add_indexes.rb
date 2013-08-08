class AddIndexes < ActiveRecord::Migration
  def up
    add_index :diagnostic_related_groups, :definition
    add_index :referral_regions, :name
    add_index :states, :abbreviation
    add_index :providers, :provider_id
    add_index :providers, :referral_region_id
    add_index :providers, :state_id
    add_index :inpatient_charges, :provider_id
    add_index :inpatient_charges, :diagnostic_related_group_id
  end

  def down
  end
end
