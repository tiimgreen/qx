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

ActiveRecord::Schema[7.2].define(version: 2024_11_27_095149) do
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

  create_table "admins", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "email", default: "", null: false
    t.boolean "active", default: true, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "delivery_items", force: :cascade do |t|
    t.integer "incoming_delivery_id", null: false
    t.string "tag_number"
    t.string "batch_number", null: false
    t.string "item_description"
    t.text "specifications"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "delivery_note_position"
    t.integer "actual_quantity"
    t.integer "target_quantity"
    t.text "quantity_check_status"
    t.text "quantity_check_comment"
    t.text "dimension_check_status"
    t.text "dimension_check_comment"
    t.text "visual_check_status"
    t.text "visual_check_comment"
    t.text "vt2_check_status"
    t.text "vt2_check_comment"
    t.text "ra_check_status"
    t.text "ra_check_comment"
    t.integer "user_id"
    t.boolean "on_hold", default: false
    t.text "on_hold_reason"
    t.datetime "on_hold_date"
    t.boolean "completed", default: false
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "ra_date"
    t.decimal "ra_value", precision: 10, scale: 2
    t.text "ra_parameters"
    t.index ["batch_number"], name: "index_delivery_items_on_batch_number"
    t.index ["incoming_delivery_id", "tag_number"], name: "index_delivery_items_on_incoming_delivery_id_and_tag_number", unique: true, where: "tag_number IS NOT NULL"
    t.index ["incoming_delivery_id"], name: "index_delivery_items_on_incoming_delivery_id"
    t.index ["user_id"], name: "index_delivery_items_on_user_id"
  end

  create_table "incoming_deliveries", force: :cascade do |t|
    t.integer "project_id", null: false
    t.date "delivery_date", null: false
    t.string "order_number", null: false
    t.string "supplier_name", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "delivery_note_number"
    t.integer "work_location_id"
    t.integer "delivery_items_count", default: 0, null: false
    t.integer "user_id"
    t.boolean "completed", default: false
    t.decimal "total_time", precision: 10, scale: 2
    t.boolean "on_hold", default: false
    t.text "on_hold_reason"
    t.datetime "on_hold_date"
    t.index ["delivery_note_number"], name: "index_incoming_deliveries_on_delivery_note_number"
    t.index ["order_number"], name: "index_incoming_deliveries_on_order_number"
    t.index ["project_id"], name: "index_incoming_deliveries_on_project_id"
    t.index ["user_id"], name: "index_incoming_deliveries_on_user_id"
    t.index ["work_location_id"], name: "index_incoming_deliveries_on_work_location_id"
  end

  create_table "inspection_defects", force: :cascade do |t|
    t.integer "quality_inspection_id", null: false
    t.text "description", null: false
    t.string "severity", null: false
    t.text "corrective_action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quality_inspection_id"], name: "index_inspection_defects_on_quality_inspection_id"
  end

  create_table "material_certificate_items", force: :cascade do |t|
    t.integer "material_certificate_id", null: false
    t.integer "delivery_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_item_id"], name: "index_material_certificate_items_on_delivery_item_id"
    t.index ["material_certificate_id", "delivery_item_id"], name: "index_material_certificate_items_unique", unique: true
    t.index ["material_certificate_id"], name: "index_material_certificate_items_on_material_certificate_id"
  end

  create_table "material_certificates", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "certificate_number", null: false
    t.string "batch_number", null: false
    t.date "issue_date", null: false
    t.string "issuer_name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_number"], name: "index_material_certificates_on_batch_number"
    t.index ["certificate_number"], name: "index_material_certificates_on_certificate_number", unique: true
    t.index ["project_id"], name: "index_material_certificates_on_project_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_permissions_on_code"
  end

  create_table "projects", force: :cascade do |t|
    t.string "project_number", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project_manager"
    t.string "client_name"
    t.integer "user_id"
    t.index ["project_number"], name: "index_projects_on_project_number", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "quality_inspections", force: :cascade do |t|
    t.integer "delivery_item_id", null: false
    t.string "inspection_type", null: false
    t.string "status", null: false
    t.datetime "inspection_date", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inspector_id"
    t.index ["delivery_item_id"], name: "index_quality_inspections_on_delivery_item_id"
    t.index ["inspection_type"], name: "index_quality_inspections_on_inspection_type"
    t.index ["inspector_id"], name: "index_quality_inspections_on_inspector_id"
    t.index ["status"], name: "index_quality_inspections_on_status"
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
    t.integer "position"
    t.index ["key"], name: "index_sectors_on_key", unique: true
  end

  create_table "user_resource_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "permission_id", null: false
    t.string "resource_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_user_resource_permissions_on_permission_id"
    t.index ["user_id", "resource_name", "permission_id"], name: "index_user_resource_permissions_uniqueness", unique: true
    t.index ["user_id"], name: "index_user_resource_permissions_on_user_id"
  end

  create_table "user_sectors", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "sector_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sector_id"], name: "index_user_sectors_on_sector_id"
    t.index ["user_id"], name: "index_user_sectors_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.boolean "active", default: true, null: false
    t.string "email", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "address", default: "", null: false
    t.string "city", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_locations", force: :cascade do |t|
    t.string "key"
    t.string "name"
    t.string "location_type"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "incoming_deliveries", "projects"
  add_foreign_key "incoming_deliveries", "users"
  add_foreign_key "incoming_deliveries", "work_locations"
  add_foreign_key "inspection_defects", "quality_inspections"
  add_foreign_key "material_certificate_items", "delivery_items"
  add_foreign_key "material_certificate_items", "material_certificates"
  add_foreign_key "material_certificates", "projects"
  add_foreign_key "projects", "users"
  add_foreign_key "quality_inspections", "delivery_items"
  add_foreign_key "quality_inspections", "users", column: "inspector_id"
  add_foreign_key "user_resource_permissions", "permissions"
  add_foreign_key "user_resource_permissions", "users"
  add_foreign_key "user_sectors", "sectors"
  add_foreign_key "user_sectors", "users"
end
