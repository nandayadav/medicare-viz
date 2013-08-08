require 'csv'
require 'row_parser'
namespace :importer do
  
  task :import => :environment do
    inpatient_file = "Medicare_Provider_Charge_Inpatient_DRG100_FY2011.csv"
    CSV.foreach(inpatient_file, {headers: true}) do |row|
      provider_id = row[1]
      drg_desc = row[0]
      region_name = row[7]
      state_name = row[5]
      drg = DiagnosticRelatedGroup.where(:definition => drg_desc).first_or_create
      referral_region = ReferralRegion.where(:name => region_name).first_or_create
      state = State.where(:abbreviation => state_name).first
      provider = Provider.find_by_provider_id(provider_id)
      if provider.nil?
        puts "Provider not found, creating for #{provider_id}"
      end
      provider ||= Provider.create!(:provider_id => provider_id, :name => row[2], :street => row[3], :city => row[4], :zip_code => row[6], :referral_region_id => referral_region.id, :state_id => state.id)
      charge = InpatientCharge.new(:provider_id => provider.id, :diagnostic_related_group_id => drg.id, :total_discharges => row[8], :avg_covered_charges => row[9], :avg_total_payments => row[10])
      charge.save!
    end
  end
  
  task :import_state_averages => :environment do 
    file = "Medicare_Charge_Inpatient_DRG100_DRG_Summary_by_DRGState_FY2011.csv"
    CSV.foreach(file, {headers: true}) do |row|
      parser = RowParser.new(row)
      parser.parse
      charge = InpatientCharge.new(:state_id => parser.state.id, :diagnostic_related_group_id => parser.drg.id, :total_discharges => row[2], :avg_covered_charges => row[3], :avg_total_payments => row[4])
      puts "Saving for #{row[1]}"
      charge.save!
    end
  end
  
  task :import_state_survey => :environment do
    file = "Survey_of_Patients_Hospital_Experiences_HCAHPS_State_Average.csv"
    options = {headers: true}
    CSV.foreach(file, options) do |row|
      state_name = row[0]
      state = State.where(:abbreviation => state_name).first
      next if state.nil?
      state.survey_not_recommended = percentage_to_num(row[27])
      state.survey_probably_recommended = percentage_to_num(row[28])
      state.survey_definitely_recommended = percentage_to_num(row[29])
      state.save!
    end
  end
  
  task :import_lat_long => :environment do
    Provider.where(:latitude => nil).find_each do |provider|
      address = "#{provider.street}, #{provider.city}, #{provider.state.abbreviation} #{provider.zip_code}"
      s = Geocoder.search(address)
      found = s.first
      if found && found.geometry
        provider.latitude = found.geometry['location']['lat']
        provider.longitude = found.geometry['location']['lng']
        provider.save!
        puts "Found for #{provider.name}"
      else
        puts "NOT FOUND: #{provider.name}"
      end
      sleep 0.5
    end
  end
  
  task :test => :environment do
    inpatient_file = "Medicare_Provider_Charge_Inpatient_DRG100_FY2011.csv"
    counter = 0
    CSV.foreach(inpatient_file, {headers: true}) do |row|
      charges = row[9]
      payments = row[10]
      if charges.to_i < payments.to_i
        counter += 1
        puts "Charges: #{charges}"
        puts "payments: #{payments}"
        puts row[2]
      end
    end
    puts "Total: #{counter}"
  end
  
  def percentage_to_num(value)
    value.gsub!("%", "").to_i
  end
end
