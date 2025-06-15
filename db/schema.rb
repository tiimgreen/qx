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

ActiveRecord::Schema[7.2].define(version: 2025_06_11_002145) do
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
    t.text "on_hold_status"
    t.text "on_hold_comment"
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

  create_table "docuvita_documents", force: :cascade do |t|
    t.string "documentable_type", null: false
    t.integer "documentable_id", null: false
    t.string "docuvita_object_id", null: false
    t.string "document_type", null: false
    t.string "filename"
    t.string "content_type"
    t.integer "byte_size"
    t.string "checksum"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qr_position"
    t.string "document_sub_type"
    t.index ["document_type"], name: "index_docuvita_documents_on_document_type"
    t.index ["documentable_type", "documentable_id"], name: "index_docuvita_documents_on_documentable"
    t.index ["docuvita_object_id"], name: "index_docuvita_documents_on_docuvita_object_id"
  end

  create_table "final_inspections", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "work_location_id"
    t.string "work_package_number"
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.text "visual_check_status"
    t.text "visual_check_comment"
    t.text "vt2_check_status"
    t.text "vt2_check_comment"
    t.datetime "completed", precision: nil
    t.decimal "total_time", precision: 10, scale: 2
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "pt2_check_status"
    t.text "pt2_check_comment"
    t.text "rt_check_status"
    t.text "rt_check_comment"
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_final_inspections_on_isometry_id"
    t.index ["project_id"], name: "index_final_inspections_on_project_id"
    t.index ["user_id"], name: "index_final_inspections_on_user_id"
    t.index ["work_location_id"], name: "index_final_inspections_on_work_location_id"
  end

  create_table "guests", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "active"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_guests_on_email", unique: true
    t.index ["project_id"], name: "index_guests_on_project_id"
    t.index ["reset_password_token"], name: "index_guests_on_reset_password_token", unique: true
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
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date"
    t.integer "isometry_id"
    t.boolean "closed", default: false
    t.index ["delivery_note_number"], name: "index_incoming_deliveries_on_delivery_note_number"
    t.index ["isometry_id"], name: "index_incoming_deliveries_on_isometry_id"
    t.index ["order_number"], name: "index_incoming_deliveries_on_order_number"
    t.index ["project_id"], name: "index_incoming_deliveries_on_project_id"
    t.index ["user_id"], name: "index_incoming_deliveries_on_user_id"
    t.index ["work_location_id"], name: "index_incoming_deliveries_on_work_location_id"
  end

  create_table "isometries", force: :cascade do |t|
    t.datetime "received_date"
    t.string "on_hold_status"
    t.string "on_hold_comment"
    t.datetime "on_hold_date"
    t.string "pid_number"
    t.integer "pid_revision"
    t.string "ped_category"
    t.boolean "gmp", default: false
    t.boolean "gdp", default: false
    t.string "system"
    t.string "pipe_class"
    t.string "material"
    t.string "line_id"
    t.integer "revision_number"
    t.boolean "revision_last", default: true
    t.integer "page_number"
    t.integer "page_total"
    t.string "medium"
    t.decimal "pipe_length", precision: 10, scale: 2
    t.integer "workshop_sn"
    t.integer "assembly_sn"
    t.integer "total_sn"
    t.integer "total_supports"
    t.integer "total_spools"
    t.integer "rt"
    t.integer "vt2"
    t.integer "pt2"
    t.boolean "dp", default: false
    t.boolean "dip", default: false
    t.string "slope_if_needed"
    t.boolean "isolation_required", default: false
    t.integer "work_package_number"
    t.integer "project_id", null: false
    t.integer "sector_id"
    t.integer "user_id"
    t.text "notes"
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qr_position"
    t.integer "qr_x_coordinate", default: -220
    t.integer "qr_y_coordinate", default: 20
    t.string "dn"
    t.boolean "draft"
    t.string "revision_letter"
    t.boolean "approved_for_production", default: true, null: false
    t.index ["approved_for_production"], name: "index_isometries_on_approved_for_production"
    t.index ["deleted"], name: "index_isometries_on_deleted"
    t.index ["line_id"], name: "index_isometries_on_line_id"
    t.index ["on_hold_status"], name: "index_isometries_on_on_hold_status"
    t.index ["pid_number"], name: "index_isometries_on_pid_number"
    t.index ["project_id", "deleted"], name: "index_isometries_on_project_id_and_deleted"
    t.index ["project_id", "on_hold_status"], name: "index_isometries_on_project_id_and_on_hold_status"
    t.index ["project_id", "revision_last"], name: "index_isometries_on_project_id_and_revision_last"
    t.index ["project_id", "system"], name: "index_isometries_on_project_id_and_system"
    t.index ["project_id"], name: "index_isometries_on_project_id"
    t.index ["received_date"], name: "index_isometries_on_received_date"
    t.index ["revision_last"], name: "index_isometries_on_revision_last"
    t.index ["revision_number"], name: "index_isometries_on_revision_number"
    t.index ["sector_id"], name: "index_isometries_on_sector_id"
    t.index ["system"], name: "index_isometries_on_system"
    t.index ["user_id"], name: "index_isometries_on_user_id"
    t.index ["work_package_number"], name: "index_isometries_on_work_package_number"
  end

  create_table "isometry_documents", force: :cascade do |t|
    t.integer "isometry_id", null: false
    t.string "qr_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isometry_id"], name: "index_isometry_documents_on_isometry_id"
  end

  create_table "isometry_material_certificates", force: :cascade do |t|
    t.integer "isometry_id", null: false
    t.integer "material_certificate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isometry_id"], name: "index_isometry_material_certificates_on_isometry_id"
    t.index ["material_certificate_id"], name: "idx_on_material_certificate_id_b920b3d784"
  end

  create_table "material_certificates", force: :cascade do |t|
    t.string "certificate_number", null: false
    t.string "batch_number", null: false
    t.date "issue_date", null: false
    t.string "issuer_name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "line_id"
    t.index ["batch_number"], name: "index_material_certificates_on_batch_number"
    t.index ["certificate_number"], name: "index_material_certificates_on_certificate_number", unique: true
  end

  create_table "on_sites", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "work_package_number"
    t.datetime "completed", precision: nil
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_on_sites_on_isometry_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pre_weldings", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "work_location_id"
    t.string "work_package_number"
    t.datetime "completed"
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date"
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_pre_weldings_on_isometry_id"
    t.index ["project_id"], name: "index_pre_weldings_on_project_id"
    t.index ["user_id"], name: "index_pre_weldings_on_user_id"
    t.index ["work_location_id"], name: "index_pre_weldings_on_work_location_id"
  end

  create_table "prefabrications", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "work_location_id"
    t.string "work_package_number"
    t.datetime "completed", precision: nil
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.integer "user_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_time", precision: 10, scale: 2
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_prefabrications_on_isometry_id"
    t.index ["project_id"], name: "index_prefabrications_on_project_id"
    t.index ["user_id"], name: "index_prefabrications_on_user_id"
    t.index ["work_location_id"], name: "index_prefabrications_on_work_location_id"
  end

  create_table "project_logs", force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.string "level", default: "info", null: false
    t.string "source", null: false
    t.text "message", null: false
    t.text "details"
    t.json "metadata"
    t.string "tag"
    t.datetime "logged_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level"], name: "index_project_logs_on_level"
    t.index ["logged_at"], name: "index_project_logs_on_logged_at"
    t.index ["project_id"], name: "index_project_logs_on_project_id"
    t.index ["source"], name: "index_project_logs_on_source"
    t.index ["tag"], name: "index_project_logs_on_tag"
    t.index ["user_id"], name: "index_project_logs_on_user_id"
  end

  create_table "project_progress_plans", force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "revision_number"
    t.boolean "revision_last"
    t.boolean "locked", default: false
    t.integer "work_type_sector_id"
    t.index ["locked"], name: "index_project_progress_plans_on_locked"
    t.index ["project_id"], name: "index_project_progress_plans_on_project_id"
    t.index ["revision_last"], name: "index_project_progress_plans_on_revision_last"
    t.index ["revision_number"], name: "index_project_progress_plans_on_revision_number"
    t.index ["work_type_sector_id"], name: "index_project_progress_plans_on_work_type_sector_id"
  end

  create_table "project_sectors", force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sector_id", null: false
    t.index ["project_id"], name: "index_project_sectors_on_project_id"
    t.index ["sector_id"], name: "index_project_sectors_on_sector_id"
  end

  create_table "project_users", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_users_on_project_id"
    t.index ["user_id"], name: "index_project_users_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "project_number", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project_manager_client"
    t.string "client_name"
    t.integer "user_id"
    t.string "project_manager_qualinox"
    t.datetime "project_end"
    t.boolean "workshop"
    t.integer "sollist_filter1_sector_id"
    t.integer "sollist_filter2_sector_id"
    t.integer "sollist_filter3_sector_id"
    t.integer "progress_filter1_sector_id"
    t.integer "progress_filter2_sector_id"
    t.boolean "archived", default: false, null: false
    t.index ["archived"], name: "index_projects_on_archived"
    t.index ["progress_filter1_sector_id"], name: "index_projects_on_progress_filter1_sector_id"
    t.index ["progress_filter2_sector_id"], name: "index_projects_on_progress_filter2_sector_id"
    t.index ["project_number"], name: "index_projects_on_project_number", unique: true
    t.index ["sollist_filter1_sector_id"], name: "index_projects_on_sollist_filter1_sector_id"
    t.index ["sollist_filter2_sector_id"], name: "index_projects_on_sollist_filter2_sector_id"
    t.index ["sollist_filter3_sector_id"], name: "index_projects_on_sollist_filter3_sector_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.string "key"
    t.index ["key"], name: "index_sectors_on_key", unique: true
  end

  create_table "site_assemblies", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "work_package_number"
    t.datetime "completed", precision: nil
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_site_assemblies_on_isometry_id"
  end

  create_table "site_deliveries", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "work_package_number"
    t.datetime "completed"
    t.text "check_spools_status"
    t.text "check_spools_comment"
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_site_deliveries_on_isometry_id"
  end

  create_table "test_packs", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "work_location_id"
    t.string "work_package_number"
    t.string "work_preparation_type"
    t.string "test_pack_type"
    t.string "dp_team"
    t.string "operating_pressure"
    t.string "dp_pressure"
    t.string "dip_team"
    t.string "dip_pressure"
    t.datetime "completed", precision: nil
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.boolean "one_test", default: false
    t.index ["isometry_id"], name: "index_test_packs_on_isometry_id"
  end

  create_table "transports", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "work_package_number"
    t.datetime "completed"
    t.text "check_spools_status"
    t.text "check_spools_comment"
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_transports_on_isometry_id"
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
    t.index ["user_id", "sector_id"], name: "index_user_sectors_on_user_id_and_sector_id", unique: true
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
    t.boolean "admin", default: false
    t.boolean "can_close_incoming_delivery", default: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weekly_progress_entries", force: :cascade do |t|
    t.integer "project_progress_plan_id", null: false
    t.integer "week_number", null: false
    t.integer "year", null: false
    t.decimal "expected_value", precision: 10, scale: 2
    t.decimal "actual_value", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_progress_plan_id", "week_number", "year"], name: "idx_weekly_progress_unique_week", unique: true
    t.index ["project_progress_plan_id"], name: "index_weekly_progress_entries_on_project_progress_plan_id"
  end

  create_table "welding_batch_assignments", force: :cascade do |t|
    t.integer "work_preparation_id", null: false
    t.integer "welding_id", null: false
    t.string "batch_number"
    t.string "batch_number1"
    t.integer "material_certificate_id"
    t.integer "material_certificate1_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_certificate1_id"], name: "index_welding_batch_assignments_on_material_certificate1_id"
    t.index ["material_certificate_id"], name: "index_welding_batch_assignments_on_material_certificate_id"
    t.index ["welding_id"], name: "index_welding_batch_assignments_on_welding_id"
    t.index ["work_preparation_id", "welding_id"], name: "index_welding_assignments_on_work_prep_and_welding", unique: true
    t.index ["work_preparation_id"], name: "index_welding_batch_assignments_on_work_preparation_id"
  end

  create_table "weldings", force: :cascade do |t|
    t.string "number"
    t.string "component"
    t.string "dimension"
    t.string "material"
    t.string "batch_number"
    t.integer "material_certificate_id"
    t.string "type_code"
    t.string "wps"
    t.string "process"
    t.string "welder"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.string "component1"
    t.string "dimension1"
    t.string "material1"
    t.string "batch_number1"
    t.integer "material_certificate1_id"
    t.string "type_code1"
    t.string "wps1"
    t.string "process1"
    t.datetime "welder1"
    t.datetime "rt_date1"
    t.datetime "pt_date1"
    t.datetime "vt_date1"
    t.string "result1"
    t.string "rt_done_by"
    t.string "pt_done_by"
    t.string "vt_done_by"
    t.boolean "is_orbital"
    t.boolean "is_manuell"
    t.index ["batch_number"], name: "index_weldings_on_batch_number"
    t.index ["isometry_id"], name: "index_weldings_on_isometry_id"
    t.index ["material_certificate1_id"], name: "index_weldings_on_material_certificate1_id"
    t.index ["material_certificate_id"], name: "index_weldings_on_material_certificate_id"
    t.index ["number"], name: "index_weldings_on_number"
  end

  create_table "work_locations", force: :cascade do |t|
    t.string "key"
    t.string "name"
    t.string "location_type"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_preparations", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "work_location_id"
    t.string "work_package_number"
    t.string "work_preparation_type"
    t.datetime "completed", precision: nil
    t.text "on_hold_status"
    t.text "on_hold_comment"
    t.datetime "on_hold_date", precision: nil
    t.integer "user_id"
    t.decimal "total_time", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "isometry_id"
    t.index ["isometry_id"], name: "index_work_preparations_on_isometry_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "final_inspections", "isometries"
  add_foreign_key "final_inspections", "projects"
  add_foreign_key "final_inspections", "users"
  add_foreign_key "final_inspections", "work_locations"
  add_foreign_key "incoming_deliveries", "isometries"
  add_foreign_key "incoming_deliveries", "projects"
  add_foreign_key "incoming_deliveries", "users"
  add_foreign_key "incoming_deliveries", "work_locations"
  add_foreign_key "isometries", "projects"
  add_foreign_key "isometries", "sectors"
  add_foreign_key "isometries", "users"
  add_foreign_key "isometry_documents", "isometries"
  add_foreign_key "isometry_material_certificates", "isometries"
  add_foreign_key "isometry_material_certificates", "material_certificates"
  add_foreign_key "on_sites", "isometries"
  add_foreign_key "on_sites", "projects"
  add_foreign_key "on_sites", "users"
  add_foreign_key "pre_weldings", "isometries"
  add_foreign_key "pre_weldings", "projects"
  add_foreign_key "pre_weldings", "users"
  add_foreign_key "pre_weldings", "work_locations"
  add_foreign_key "prefabrications", "isometries"
  add_foreign_key "prefabrications", "projects"
  add_foreign_key "prefabrications", "users"
  add_foreign_key "prefabrications", "work_locations"
  add_foreign_key "project_logs", "projects"
  add_foreign_key "project_logs", "users"
  add_foreign_key "project_progress_plans", "projects"
  add_foreign_key "project_progress_plans", "sectors", column: "work_type_sector_id"
  add_foreign_key "project_sectors", "projects"
  add_foreign_key "project_sectors", "sectors"
  add_foreign_key "project_users", "projects"
  add_foreign_key "project_users", "users"
  add_foreign_key "projects", "sectors", column: "progress_filter1_sector_id"
  add_foreign_key "projects", "sectors", column: "progress_filter2_sector_id"
  add_foreign_key "projects", "sectors", column: "sollist_filter1_sector_id"
  add_foreign_key "projects", "sectors", column: "sollist_filter2_sector_id"
  add_foreign_key "projects", "sectors", column: "sollist_filter3_sector_id"
  add_foreign_key "projects", "users"
  add_foreign_key "site_assemblies", "isometries"
  add_foreign_key "site_assemblies", "projects"
  add_foreign_key "site_assemblies", "users"
  add_foreign_key "site_deliveries", "isometries"
  add_foreign_key "site_deliveries", "projects"
  add_foreign_key "site_deliveries", "users"
  add_foreign_key "test_packs", "isometries"
  add_foreign_key "test_packs", "projects"
  add_foreign_key "test_packs", "projects"
  add_foreign_key "test_packs", "users"
  add_foreign_key "test_packs", "users"
  add_foreign_key "test_packs", "work_locations"
  add_foreign_key "test_packs", "work_locations"
  add_foreign_key "transports", "isometries"
  add_foreign_key "transports", "projects"
  add_foreign_key "transports", "users"
  add_foreign_key "user_resource_permissions", "permissions"
  add_foreign_key "user_resource_permissions", "users"
  add_foreign_key "user_sectors", "sectors"
  add_foreign_key "user_sectors", "users"
  add_foreign_key "weekly_progress_entries", "project_progress_plans"
  add_foreign_key "welding_batch_assignments", "material_certificates"
  add_foreign_key "welding_batch_assignments", "material_certificates", column: "material_certificate1_id"
  add_foreign_key "welding_batch_assignments", "weldings"
  add_foreign_key "welding_batch_assignments", "work_preparations"
  add_foreign_key "weldings", "isometries"
  add_foreign_key "weldings", "material_certificates"
  add_foreign_key "weldings", "material_certificates", column: "material_certificate1_id"
  add_foreign_key "work_preparations", "isometries"
  add_foreign_key "work_preparations", "projects"
  add_foreign_key "work_preparations", "users"
  add_foreign_key "work_preparations", "work_locations"
end
