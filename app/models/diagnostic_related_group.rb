class DiagnosticRelatedGroup < ActiveRecord::Base
  has_many :inpatient_charges, :dependent => :destroy
  
  def charges
    @charges ||= inpatient_charges
  end
  
  #Computes standard deviation on the fly for given measurement
  def std_deviation(measure = :avg_total_payments)
    measure_values  = charges.map{|c| c.read_attribute(measure)}
    stats = DescriptiveStatistics::Stats.new(measure_values)
    @std_deviation ||= stats.variance
  end
  
  def count
    charges.size
  end
  
end
