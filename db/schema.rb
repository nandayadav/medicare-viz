# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130821192800) do

  create_table "diagnostic_related_groups", :force => true do |t|
    t.string   "definition"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "diagnostic_related_groups", ["definition"], :name => "index_diagnostic_related_groups_on_definition"

  create_table "inpatient_charges", :force => true do |t|
    t.integer  "provider_id"
    t.integer  "diagnostic_related_group_id"
    t.float    "total_discharges"
    t.float    "avg_covered_charges"
    t.float    "avg_total_payments"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "state_id"
  end

  add_index "inpatient_charges", ["diagnostic_related_group_id"], :name => "index_inpatient_charges_on_diagnostic_related_group_id"
  add_index "inpatient_charges", ["provider_id"], :name => "index_inpatient_charges_on_provider_id"

  create_table "providers", :force => true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "city"
    t.integer  "provider_id"
    t.integer  "zip_code"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "referral_region_id"
    t.integer  "state_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "state_code"
  end

  add_index "providers", ["provider_id"], :name => "index_providers_on_provider_id"
  add_index "providers", ["referral_region_id"], :name => "index_providers_on_referral_region_id"
  add_index "providers", ["state_id"], :name => "index_providers_on_state_id"

  create_table "referral_regions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "referral_regions", ["name"], :name => "index_referral_regions_on_name"

  create_table "states", :force => true do |t|
    t.string   "name"
    t.string   "abbreviation"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "survey_not_recommended"
    t.integer  "survey_probably_recommended"
    t.integer  "survey_definitely_recommended"
  end

  add_index "states", ["abbreviation"], :name => "index_states_on_abbreviation"

end
