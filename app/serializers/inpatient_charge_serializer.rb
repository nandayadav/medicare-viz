class InpatientChargeSerializer < ActiveModel::Serializer
  attributes :id, :provider_id, :avg_covered_charges, :avg_total_payments, :total_discharges, :provider, :diagnostic_related_group_id
  
  # def cached_provider
  #   @provider ||= provider
  # end

  
  def provider
    p = object.provider
    drg = object.diagnostic_related_group
    {name: p.name, state_code: p.state_code, longitude: p.longitude, latitude: p.latitude, city: p.city, drg: drg.definition}
  end
  
  #Average of 
  def national_mean_charges
    drg = object.diagnostic_related_group
    charges = drg.inpatient_charges.where(:state_id => nil)
    measure_values  = charges.map(&:avg_covered_charges)
    stats = DescriptiveStatistics::Stats.new(measure_values)
    stats.mean
  end
end
