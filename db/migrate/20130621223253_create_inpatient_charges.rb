class CreateInpatientCharges < ActiveRecord::Migration
  def change
    create_table :inpatient_charges do |t|
      t.integer     :provider_id, :diagnostic_related_group_id
      t.float         :total_discharges, :avg_covered_charges, :avg_total_payments
      t.timestamps
    end
  end
end
