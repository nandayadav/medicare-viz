namespace :stats do
  
  task :generate => :environment do
    DiagnosticRelatedGroup.limit(5).each do |drg|
      payments = drg.inpatient_charges.map(&:avg_total_payments)
      # covered_charges = drg.inpatient_charges.map(&:avg_covered_charges)
      # discharges = drg.inpatient_charges.map(&:total_discharges)
      # payments_mean = 0.0
      # payments_std = 0.0
      
      stats = DescriptiveStatistics::Stats.new(payments)
      puts "For #{drg.definition}"
      puts "Total charges count: #{drg.inpatient_charges.count}"
      puts "Mean: #{stats.mean}"
      puts "STD: #{stats.standard_deviation}"
      
    end
  end
end
