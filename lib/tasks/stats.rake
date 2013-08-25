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
  
  task :weighted_means => :environment do
    
    DiagnosticRelatedGroup.all.each do |drg|
      charges = drg.inpatient_charges.where(:state_id => nil)
      total_payments, total_charges, divider = 0.0, 0.0, 0.0
      charges.each do |c|
        divider += c.total_discharges
        total_charges += c.total_discharges*c.avg_covered_charges
        total_payments += c.total_discharges*c.avg_total_payments
      end
      weighted_mean_payments = (total_payments/divider).to_f
      weighted_mean_charges = (total_charges/divider).to_f
      puts "Charges: #{weighted_mean_charges}"
      puts "Payments: #{weighted_mean_payments}"
      drg.update_attributes({weighted_mean_charges: weighted_mean_charges, weighted_mean_payments: weighted_mean_payments})
    end
  end
end
