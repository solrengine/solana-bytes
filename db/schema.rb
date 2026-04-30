# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_29_053519) do
  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.text "properties"
    t.datetime "time"
    t.integer "user_id"
    t.integer "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "country"
    t.string "device_type"
    t.text "landing_page"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.integer "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["country"], name: "idx_ahoy_visits_country"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "challenge_results", force: :cascade do |t|
    t.string "account_address", null: false
    t.integer "attempts", null: false
    t.string "challenge_token_digest"
    t.datetime "created_at", null: false
    t.integer "streak", null: false
    t.string "target_field", null: false
    t.decimal "time_seconds", null: false
    t.integer "total_stars", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["account_address"], name: "idx_challenge_results_account_address"
    t.index ["challenge_token_digest"], name: "index_challenge_results_on_challenge_token_digest", unique: true
    t.index ["created_at"], name: "idx_challenge_results_recent"
    t.index ["streak", "time_seconds"], name: "idx_challenge_results_leaderboard"
    t.index ["target_field"], name: "idx_challenge_results_target_field"
    t.index ["user_id"], name: "index_challenge_results_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nonce"
    t.datetime "nonce_expires_at"
    t.datetime "updated_at", null: false
    t.string "wallet_address", null: false
    t.index ["wallet_address"], name: "index_users_on_wallet_address", unique: true
  end

  add_foreign_key "challenge_results", "users"
end
