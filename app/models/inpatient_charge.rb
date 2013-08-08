class InpatientCharge < ActiveRecord::Base
  belongs_to :provider #For given hospital
  belongs_to :state  #State average
  belongs_to :diagnostic_related_group
  
  attr_accessible :provider_id, :total_discharges, :avg_covered_charges, :avg_total_payments, :diagnostic_related_group_id, :state_id
  
  def state_code
    provider.state.abbreviation
  end
  
  def as_json(opts)
    json = super(opts)
    p = provider
    drg = diagnostic_related_group
    provider_hash = {:state_code => p.state_code, :provider_city => p.city, :provider_name => p.name, :longitude => p.longitude, :latitude => p.latitude, :drg => drg.definition}
    json.merge!(provider_hash)
    json
  end
end
