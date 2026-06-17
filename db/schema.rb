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

ActiveRecord::Schema[8.1].define(version: 2026_06_17_150000) do
  create_table "campaigns", force: :cascade do |t|
    t.decimal "bonus_goal_amount", precision: 12, scale: 2
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "goal_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "organization_name"
    t.integer "status", default: 0, null: false
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "donations", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.text "dedication_message"
    t.integer "display_preference", default: 0, null: false
    t.string "donor_name"
    t.integer "frequency", default: 0, null: false
    t.integer "months"
    t.string "payment_intent_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "status"], name: "index_donations_on_campaign_id_and_status"
    t.index ["campaign_id"], name: "index_donations_on_campaign_id"
  end

  add_foreign_key "donations", "campaigns"
end
