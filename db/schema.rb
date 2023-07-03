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

ActiveRecord::Schema[7.0].define(version: 2023_06_30_171003) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "baptisms", force: :cascade do |t|
    t.date "baptized_at"
    t.string "baptized_location"
    t.string "christian_name"
    t.string "godfather"
    t.string "godmother"
    t.string "presbyter"
    t.integer "godfather_id"
    t.integer "godmother_id"
    t.integer "presbyter_id"
    t.integer "parishioner_id"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "confirmations", force: :cascade do |t|
    t.date "confirmed_at"
    t.string "confirmed_location"
    t.string "christian_name"
    t.string "godfather"
    t.string "godmother"
    t.string "presbyter"
    t.integer "godfather_id"
    t.integer "godmother_id"
    t.integer "presbyter_id"
    t.integer "parishioner_id"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "eucharists", force: :cascade do |t|
    t.date "eucharist_at"
    t.string "eucharist_location"
    t.string "christian_name"
    t.string "godfather"
    t.string "godmother"
    t.string "presbyter"
    t.integer "godfather_id"
    t.integer "godmother_id"
    t.integer "presbyter_id"
    t.integer "parishioner_id"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "households", primary_key: "home_number", id: :string, force: :cascade do |t|
    t.integer "head_of_household"
    t.boolean "special", default: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "marriages", force: :cascade do |t|
    t.date "marriage_at"
    t.string "marriage_location"
    t.string "groom"
    t.string "bride"
    t.integer "groom_id"
    t.integer "bride_id"
    t.string "groom_birth_at"
    t.string "groom_father"
    t.string "groom_mother"
    t.string "bride_birth_at"
    t.string "bride_father"
    t.string "bride_mother"
    t.string "presbyter"
    t.integer "presbyter_id"
    t.string "witness1"
    t.string "witness2"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parishioners", force: :cascade do |t|
    t.string "name"
    t.string "gender"
    t.date "birth_at"
    t.string "postal_code"
    t.string "address"
    t.string "father"
    t.string "mother"
    t.string "home_phone"
    t.string "mobile_phone"
    t.string "nationality"
    t.string "profession"
    t.string "company_name"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mother_id"
    t.integer "father_id"
    t.string "home_number"
    t.integer "sibling_number", default: 0
    t.integer "children_number", default: 0
    t.date "move_in_date"
    t.string "original_parish"
    t.date "move_out_date"
    t.string "move_out_reason"
    t.string "destination_parish"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "baptisms", "parishioners", column: "godfather_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "baptisms", "parishioners", column: "godmother_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "baptisms", "parishioners", column: "presbyter_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "baptisms", "parishioners", on_update: :cascade, on_delete: :cascade
  add_foreign_key "confirmations", "parishioners", column: "godfather_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "confirmations", "parishioners", column: "godmother_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "confirmations", "parishioners", column: "presbyter_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "confirmations", "parishioners", on_update: :cascade, on_delete: :cascade
  add_foreign_key "eucharists", "parishioners", column: "godfather_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", column: "godfather_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", column: "godmother_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", column: "godmother_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", column: "presbyter_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", column: "presbyter_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "eucharists", "parishioners", on_update: :cascade, on_delete: :cascade
  add_foreign_key "eucharists", "parishioners", on_update: :cascade, on_delete: :cascade
  add_foreign_key "households", "parishioners", column: "head_of_household", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "households", column: "home_number", primary_key: "home_number", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "parishioners", column: "father_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "parishioners", "parishioners", column: "mother_id", on_update: :cascade, on_delete: :nullify
end
