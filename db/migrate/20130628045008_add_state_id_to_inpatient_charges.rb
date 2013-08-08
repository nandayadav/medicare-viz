class AddStateIdToInpatientCharges < ActiveRecord::Migration
  def change
    add_column :inpatient_charges, :state_id, :integer
  end
end
