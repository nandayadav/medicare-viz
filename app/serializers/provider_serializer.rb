class ProviderSerializer < ActiveModel::Serializer
  attributes :id, :name, :street, :city, :state_code, :zip_code, :charges
  
  
  #Using custom charges array instead of association(which includes redundant providers info)
  #Include mean weighted payments/charges for national level as well as state level
  def charges
    chrgs = object.inpatient_charges.includes(:diagnostic_related_group)
    arr = []
    state = object.state
    state_charges_hash = state.inpatient_charges.inject(HashWithIndifferentAccess.new) {|hash, charge| hash[charge.diagnostic_related_group_id] = charge; hash }
    chrgs.each do |charge|
      drg = charge.diagnostic_related_group
      h = {id: charge.id, drg_id: drg.id, drg_definition: drg.definition, avg_covered_charges: charge.avg_covered_charges, weighted_mean_payments: drg.weighted_mean_payments, weighted_mean_charges: drg.weighted_mean_charges, avg_total_payments: charge.avg_total_payments, total_discharges: charge.total_discharges}
      if record = state_charges_hash[drg.id]
        h.merge!(state_avg_covered_charges: record[:avg_covered_charges], state_avg_total_payments: record[:avg_total_payments], state_total_discharges: record[:total_discharges])
      end
      arr << h
    end
    arr
  end
    
end
