class CreateProviders < ActiveRecord::Migration
  def change
    create_table :providers do |t|
      t.string :name, :street, :city, :state, :referral_region
      t.integer :provider_id, :zip_code
      t.float :total_discharges, :avg_covered_charges, :avg_total_payments
      t.timestamps
    end
  end
end
