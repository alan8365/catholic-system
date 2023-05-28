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

ActiveRecord::Schema[7.0].define(version: 2023_05_26_163713) do
  create_table "households", primary_key: "home_number", id: :string, force: :cascade do |t|
    t.integer "head_of_household"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parishioners", force: :cascade do |t|
    t.string "name"
    t.string "gender"
    t.date "birth_at"
    t.string "postal_code"
    t.string "address"
    t.string "photo_url"
    t.string "father"
    t.string "mother"
    t.string "spouse"
    t.string "home_phone"
    t.string "mobile_phone"
    t.string "nationality"
    t.string "profession"
    t.string "company_name"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "spouse_id"
    t.integer "mother_id"
    t.integer "father_id"
    t.string "home_number"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.string "password_digest"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_admin", default: false
    t.boolean "is_modulator", default: false
  end

  add_foreign_key "households", "parishioners", column: "head_of_household", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "households", column: "home_number", primary_key: "home_number", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "parishioners", column: "father_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "parishioners", column: "mother_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "parishioners", column: "spouse_id", on_update: :cascade, on_delete: :nullify
end
