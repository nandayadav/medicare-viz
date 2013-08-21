class InpatientChargeSerializer < ActiveModel::Serializer
  attributes :id, :avg_covered_charges, :avg_total_payments, :total_discharges
  
  #Average of 
  def national_mean_charges
    drg = object.diagnostic_related_group
    charges = drg.inpatient_charges.where(:state_id => nil)
    measure_values  = charges.map(&:avg_covered_charges)
    stats = DescriptiveStatistics::Stats.new(measure_values)
    stats.mean
  end
end
