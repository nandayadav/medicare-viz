class ProviderSerializer < ActiveModel::Serializer
  attributes :id, :name, :street, :city, :state_code, :zip_code, :charges
  
  
  #Using custom charges array instead of association(which includes redundant providers info)
  def charges
    chrgs = object.inpatient_charges.includes(:diagnostic_related_group)
    arr = []
    attrs = [:id, :avg_covered_charges, :avg_total_payments, :total_discharges]
    chrgs.each do |charge|
      drg = charge.diagnostic_related_group
      arr << {id: charge.id, drg_id: drg.id, drg_definition: drg.definition, avg_covered_charges: charge.avg_covered_charges, weighted_mean_payments: drg.weighted_mean_payments, weighted_mean_charges: drg.weighted_mean_charges, avg_total_payments: charge.avg_total_payments, total_discharges: charge.total_discharges}
    end
    arr
  end
    
end
