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

ActiveRecord::Schema[8.1].define(version: 2026_04_03_035645) do
  create_table "challenge_results", force: :cascade do |t|
    t.string "account_address"
    t.integer "attempts"
    t.datetime "created_at", null: false
    t.integer "stars"
    t.integer "streak"
    t.string "target_field"
    t.decimal "time_seconds"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
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
