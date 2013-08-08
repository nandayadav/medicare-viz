class CreateReferralRegions < ActiveRecord::Migration
  def change
    create_table :referral_regions do |t|
      t.string       :name
      t.timestamps
    end
    add_column :providers, :referral_region_id, :integer
    add_column :providers, :diagnostic_related_group_id, :integer
  end
end
