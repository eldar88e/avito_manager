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

ActiveRecord::Schema[8.0].define(version: 2025_09_12_120807) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "ad_imports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "description"
    t.bigint "price"
    t.bigint "old_price"
    t.string "md5_hash", null: false
    t.boolean "deleted", default: false
    t.bigint "price_updated"
    t.jsonb "images", default: {}
    t.bigint "run_id", null: false
    t.bigint "touched_run_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.string "category"
    t.jsonb "extra"
    t.index ["md5_hash"], name: "index_ad_imports_on_md5_hash", unique: true
    t.index ["run_id"], name: "index_ad_imports_on_run_id"
    t.index ["touched_run_id"], name: "index_ad_imports_on_touched_run_id"
    t.index ["user_id"], name: "index_ad_imports_on_user_id"
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "city", null: false
    t.string "slogan"
    t.jsonb "slogan_params"
    t.boolean "active", default: false, null: false
    t.string "description"
    t.integer "total_games"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_addresses_on_store_id"
  end

  create_table "ads", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "address_id", null: false
    t.string "file_id"
    t.string "adable_type", null: false
    t.bigint "adable_id", null: false
    t.bigint "user_id", null: false
    t.boolean "deleted", default: false, null: false
    t.boolean "banned", default: false, null: false
    t.datetime "banned_until"
    t.bigint "avito_id"
    t.string "full_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adable_type", "adable_id"], name: "index_ads_on_adable"
    t.index ["address_id"], name: "index_ads_on_address_id"
    t.index ["store_id"], name: "index_ads_on_store_id"
    t.index ["user_id"], name: "index_ads_on_user_id"
  end

  create_table "avito_tokens", force: :cascade do |t|
    t.string "access_token", null: false
    t.integer "expires_in", null: false
    t.string "token_type", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_avito_tokens_on_store_id"
  end

  create_table "image_layers", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "layer_params", default: {}
    t.integer "layer_type", default: 0, null: false
    t.bigint "store_id", null: false
    t.integer "menuindex", default: 0, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_image_layers_on_store_id"
  end

  create_table "runs", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string "variable"
    t.string "value"
    t.string "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "variable"], name: "index_settings_on_user_id_and_variable", unique: true
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "stores", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "var", null: false
    t.string "ad_status"
    t.string "category", null: false
    t.string "goods_type", null: false
    t.string "ad_type", null: false
    t.text "description", null: false
    t.string "condition", null: false
    t.string "allow_email", null: false
    t.string "manager_name", null: false
    t.string "contact_phone", null: false
    t.integer "menuindex", default: 0
    t.jsonb "img_params"
    t.boolean "active", default: false, null: false
    t.string "contact_method"
    t.text "desc_ad_import"
    t.text "desc_product"
    t.string "availability"
    t.string "client_id"
    t.string "client_secret"
    t.integer "percent", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.index ["contact_phone"], name: "index_stores_on_contact_phone", unique: true
    t.index ["user_id", "var"], name: "index_stores_on_user_id_and_var", unique: true
    t.index ["user_id"], name: "index_stores_on_user_id"
  end

  create_table "streets", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "address_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id", "title"], name: "index_streets_on_address_id_and_title", unique: true
    t.index ["address_id"], name: "index_streets_on_address_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ad_imports", "users"
  add_foreign_key "addresses", "stores"
  add_foreign_key "ads", "addresses"
  add_foreign_key "ads", "stores"
  add_foreign_key "ads", "users"
  add_foreign_key "avito_tokens", "stores"
  add_foreign_key "image_layers", "stores"
  add_foreign_key "settings", "users"
  add_foreign_key "stores", "users"
  add_foreign_key "streets", "addresses"
end
