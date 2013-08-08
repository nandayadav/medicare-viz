class State < ActiveRecord::Base
  has_many :providers
  has_many :inpatient_charges, :dependent => :destroy
  
  def total_payments
    inpatient_charges.map(&:avg_total_payments).reduce(:+).to_i
  end
  
  def charges
    @charges ||= inpatient_charges
  end
  
  def std_deviation_payments
    std_deviation
  end
  
  def std_deviation_charges
    std_deviation(:avg_covered_charges)
  end
  
  def std_deviation_discharges
    std_deviation(:total_discharges)
  end
  
  def count
    charges.size
  end
  
  private
  
  #Computes standard deviation on the fly for given measurement
  def std_deviation(measure = :avg_total_payments)
    measure_values  = charges.map{|c| c.read_attribute(measure)}
    stats = DescriptiveStatistics::Stats.new(measure_values)
    stats.standard_deviation
  end
  

end
