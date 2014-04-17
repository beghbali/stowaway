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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140417031712) do

  create_table "coupons", force: true do |t|
    t.string   "type"
    t.string   "code"
    t.decimal  "discount",   precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expires_at"
  end

  create_table "payments", force: true do |t|
    t.decimal  "amount",             precision: 8, scale: 2, default: 0.0
    t.decimal  "credits_used",       precision: 8, scale: 2, default: 0.0
    t.decimal  "credit_card_charge", precision: 8, scale: 2, default: 0.0
    t.decimal  "fee",                precision: 8, scale: 2, default: 0.0
    t.string   "reference"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_id"
    t.integer  "receipt_id"
  end

  create_table "receipts", force: true do |t|
    t.string   "generated_by"
    t.string   "billed_to"
    t.integer  "user_id"
    t.datetime "ride_requested_at"
    t.string   "pickup_location"
    t.string   "dropoff_location"
    t.string   "payment_card"
    t.decimal  "total_amount",      precision: 8,  scale: 2
    t.decimal  "base_amount",       precision: 8,  scale: 2
    t.decimal  "distance_amount",   precision: 8,  scale: 2
    t.decimal  "time_amount",       precision: 8,  scale: 2
    t.decimal  "surge_amount",      precision: 8,  scale: 2
    t.float    "surge_multiple"
    t.decimal  "other_amount",      precision: 8,  scale: 2
    t.string   "other_description"
    t.string   "driver_name"
    t.float    "distance"
    t.integer  "duration"
    t.float    "average_speed"
    t.string   "map_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "pickup_lat",        precision: 16, scale: 12
    t.decimal  "pickup_lng",        precision: 16, scale: 12
  end

  create_table "requests", force: true do |t|
    t.integer  "user_id"
    t.string   "status",                                    default: "outstanding"
    t.string   "pickup_address"
    t.string   "dropoff_address"
    t.decimal  "pickup_lat",      precision: 16, scale: 12
    t.decimal  "pickup_lng",      precision: 16, scale: 12
    t.decimal  "dropoff_lat",     precision: 16, scale: 12
    t.decimal  "dropoff_lng",     precision: 16, scale: 12
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ride_id"
    t.string   "designation"
    t.integer  "public_id"
    t.datetime "deleted_at"
    t.decimal  "last_lat",        precision: 16, scale: 12
    t.decimal  "last_lng",        precision: 16, scale: 12
    t.integer  "vicinity_count",                            default: 0
    t.datetime "checkedin_at"
    t.integer  "receipt_id"
    t.string   "coupon_code"
  end

  add_index "requests", ["deleted_at"], name: "index_requests_on_deleted_at", using: :btree
  add_index "requests", ["designation"], name: "index_requests_on_designation", using: :btree
  add_index "requests", ["status"], name: "index_requests_on_status", using: :btree

  create_table "rides", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location_channel"
    t.integer  "public_id"
    t.string   "suggested_dropoff_address"
    t.decimal  "suggested_dropoff_lat",     precision: 16, scale: 12
    t.decimal  "suggested_dropoff_lng",     precision: 16, scale: 12
    t.string   "suggested_pickup_address"
    t.decimal  "suggested_pickup_lat",      precision: 16, scale: 12
    t.decimal  "suggested_pickup_lng",      precision: 16, scale: 12
    t.datetime "deleted_at"
    t.integer  "receipt_id"
  end

  add_index "rides", ["deleted_at"], name: "index_rides_on_deleted_at", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "provider"
    t.string   "uid"
    t.string   "email"
    t.string   "image_url"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email_provider"
    t.string   "gender"
    t.string   "location"
    t.boolean  "verified"
    t.string   "profile_url"
    t.string   "stowaway_email"
    t.string   "gmail_access_token"
    t.string   "gmail_refresh_token"
    t.string   "stowaway_email_password"
    t.integer  "public_id"
    t.datetime "last_processed_email_sent_at"
    t.string   "stripe_token"
    t.string   "device_type"
    t.string   "device_token"
    t.string   "customer_id"
    t.decimal  "credits",                       precision: 8, scale: 2, default: 0.0
    t.string   "gmail_access_token_expires_at"
    t.string   "coupon_code"
  end

end
