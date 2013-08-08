class Provider < ActiveRecord::Base
  has_many :inpatient_charges, :dependent => :destroy
  belongs_to :referral_region
  belongs_to :state
  
  validates :provider_id, :uniqueness => true, :presence => true
  attr_accessible :provider_id, :name, :street, :city, :state, :zip_code, :referral_region_id, :state_id
  
  def address
    "#{street}, #{city}, #{state.abbreviation} #{zip_code}"
  end
  
  def total_payments
    #inpatient_charges.first.avg_covered_charges.to_i
    inpatient_charges.map(&:avg_total_payments).reduce(:+).to_i
  end
  
  
  
  def state_code
    state.abbreviation
  end
  
end
