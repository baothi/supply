# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_04_080452) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "provider"
    t.string "encrypted_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.string "followable_type", null: false
    t.integer "followable_id", null: false
    t.string "follower_type", null: false
    t.integer "follower_id", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_friendly_id_slugs_on_deleted_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "spree_addresses", id: :serial, force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "zipcode"
    t.string "phone"
    t.string "state_name"
    t.string "alternative_phone"
    t.string "company"
    t.integer "state_id"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name_of_state"
    t.string "business_name"
    t.string "state_abbr"
    t.index ["country_id"], name: "index_spree_addresses_on_country_id"
    t.index ["firstname"], name: "index_addresses_on_firstname"
    t.index ["lastname"], name: "index_addresses_on_lastname"
    t.index ["state_id"], name: "index_spree_addresses_on_state_id"
  end

  create_table "spree_adjustments", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.integer "source_id"
    t.string "adjustable_type"
    t.integer "adjustable_id"
    t.decimal "amount", precision: 10, scale: 2
    t.string "label"
    t.boolean "mandatory"
    t.boolean "eligible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.integer "order_id", null: false
    t.boolean "included", default: false
    t.index ["adjustable_id", "adjustable_type"], name: "index_spree_adjustments_on_adjustable_id_and_adjustable_type"
    t.index ["eligible"], name: "index_spree_adjustments_on_eligible"
    t.index ["order_id"], name: "index_spree_adjustments_on_order_id"
    t.index ["source_id", "source_type"], name: "index_spree_adjustments_on_source_id_and_source_type"
  end

  create_table "spree_assets", id: :serial, force: :cascade do |t|
    t.string "viewable_type"
    t.integer "viewable_id"
    t.integer "attachment_width"
    t.integer "attachment_height"
    t.integer "attachment_file_size"
    t.integer "position"
    t.string "attachment_content_type"
    t.string "attachment_file_name"
    t.string "type", limit: 75
    t.datetime "attachment_updated_at"
    t.text "alt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "hash_value"
    t.integer "previous_image_id"
    t.index ["hash_value"], name: "index_spree_assets_on_hash_value"
    t.index ["position"], name: "index_spree_assets_on_position"
    t.index ["viewable_id"], name: "index_assets_on_viewable_id"
    t.index ["viewable_type", "type"], name: "index_assets_on_viewable_type_and_type"
  end

  create_table "spree_calculators", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "calculable_type"
    t.integer "calculable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preferences"
    t.datetime "deleted_at"
    t.index ["calculable_id", "calculable_type"], name: "index_spree_calculators_on_calculable_id_and_calculable_type"
    t.index ["deleted_at"], name: "index_spree_calculators_on_deleted_at"
    t.index ["id", "type"], name: "index_spree_calculators_on_id_and_type"
  end

  create_table "spree_category_option_matches", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.integer "platform_category_option_id", null: false
    t.integer "supplier_category_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_category_option_id", "supplier_category_option_id"], name: "spree_category_option_matches_on_platform_and_supplier_category", unique: true
    t.index ["supplier_id"], name: "index_spree_category_option_matches_on_supplier_id"
  end

  create_table "spree_countries", id: :serial, force: :cascade do |t|
    t.string "iso_name"
    t.string "iso"
    t.string "iso3"
    t.string "name"
    t.integer "numcode"
    t.boolean "states_required", default: false
    t.datetime "updated_at"
    t.boolean "zipcode_required", default: true
  end

  create_table "spree_couriers", id: :serial, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "website"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_spree_couriers_on_code"
    t.index ["name"], name: "index_spree_couriers_on_name"
  end

  create_table "spree_credit_cards", id: :serial, force: :cascade do |t|
    t.string "month"
    t.string "year"
    t.string "cc_type"
    t.string "last_digits"
    t.integer "address_id"
    t.string "gateway_customer_profile_id"
    t.string "gateway_payment_profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "user_id"
    t.integer "payment_method_id"
    t.boolean "default", default: false, null: false
    t.index ["address_id"], name: "index_spree_credit_cards_on_address_id"
    t.index ["payment_method_id"], name: "index_spree_credit_cards_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_credit_cards_on_user_id"
  end

  create_table "spree_customer_returns", id: :serial, force: :cascade do |t|
    t.string "number"
    t.integer "stock_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_edi_fulfillment_notices", id: :serial, force: :cascade do |t|
    t.string "asn_number"
    t.datetime "asn_generated_at"
    t.string "sender_name"
    t.string "sender_identifier"
    t.string "purchase_order_number"
    t.string "carrier_name"
    t.string "scac_code"
    t.date "po_created_at"
    t.date "estimated_delivery_date"
    t.date "shipped_date"
    t.string "customer_order_number"
    t.string "internal_vendor_number"
    t.integer "num_items"
    t.text "raw_xml"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_favorites", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_spree_favorites_on_product_id"
    t.index ["retailer_id"], name: "index_spree_favorites_on_retailer_id"
  end

  create_table "spree_featured_banners", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "title"
    t.text "description"
    t.integer "taxon_id"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_identifier"], name: "index_spree_featured_banners_on_internal_identifier"
    t.index ["taxon_id"], name: "index_spree_featured_banners_on_taxon_id"
  end

  create_table "spree_gateways", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.string "environment", default: "development"
    t.string "server", default: "test"
    t.boolean "test_mode", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preferences"
    t.index ["active"], name: "index_spree_gateways_on_active"
    t.index ["test_mode"], name: "index_spree_gateways_on_test_mode"
  end

  create_table "spree_groupings", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "name"
    t.text "description"
    t.string "group_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mini_identifier"
    t.string "slug"
    t.string "display_name"
    t.index ["internal_identifier"], name: "index_spree_groupings_on_internal_identifier"
    t.index ["mini_identifier"], name: "index_spree_groupings_on_mini_identifier", unique: true
    t.index ["slug"], name: "index_spree_groupings_on_slug", unique: true
  end

  create_table "spree_inventory_units", id: :serial, force: :cascade do |t|
    t.string "state"
    t.integer "variant_id"
    t.integer "order_id"
    t.integer "shipment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pending", default: true
    t.integer "line_item_id"
    t.datetime "cancelled_at"
    t.index ["line_item_id"], name: "index_spree_inventory_units_on_line_item_id"
    t.index ["order_id"], name: "index_inventory_units_on_order_id"
    t.index ["shipment_id"], name: "index_inventory_units_on_shipment_id"
    t.index ["variant_id"], name: "index_inventory_units_on_variant_id"
  end

  create_table "spree_line_items", id: :serial, force: :cascade do |t|
    t.integer "variant_id"
    t.integer "order_id"
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.decimal "cost_price", precision: 10, scale: 2
    t.integer "tax_category_id"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "pre_tax_amount", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "supplier_shopify_identifier"
    t.string "retailer_shopify_identifier"
    t.string "internal_identifier"
    t.decimal "shipping_cost", precision: 8, scale: 2, default: "0.0"
    t.decimal "sold_at_price", precision: 8, scale: 2, default: "0.0"
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.string "line_item_number"
    t.string "purchase_order_number"
    t.datetime "fulfilled_at"
    t.datetime "cancelled_at"
    t.datetime "fulfillment_sent_to_retailer_at"
    t.datetime "refunded_subtotal_at"
    t.datetime "refunded_shipping_at"
    t.datetime "refunded_tax_at"
    t.datetime "refunded_total_at"
    t.datetime "invalid_fulfilled_at"
    t.index ["internal_identifier"], name: "index_spree_line_items_on_internal_identifier"
    t.index ["order_id"], name: "index_spree_line_items_on_order_id"
    t.index ["tax_category_id"], name: "index_spree_line_items_on_tax_category_id"
    t.index ["variant_id"], name: "index_spree_line_items_on_variant_id"
  end

  create_table "spree_log_entries", id: :serial, force: :cascade do |t|
    t.string "source_type"
    t.integer "source_id"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id", "source_type"], name: "index_spree_log_entries_on_source_id_and_source_type"
  end

  create_table "spree_long_running_jobs", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.integer "user_id"
    t.string "initiated_by", null: false
    t.string "action_type", null: false
    t.string "job_type", null: false
    t.string "status", null: false
    t.string "option_1"
    t.string "option_2"
    t.string "option_3"
    t.string "option_4"
    t.string "option_5"
    t.string "option_6"
    t.string "option_7"
    t.string "option_8"
    t.string "option_9"
    t.string "option_10"
    t.string "shopify_publish_status"
    t.datetime "time_started"
    t.datetime "time_completed"
    t.decimal "completion_time", precision: 8, scale: 2
    t.integer "num_of_records_processed"
    t.integer "num_of_records_not_processed"
    t.integer "total_num_of_records"
    t.integer "num_of_errors"
    t.boolean "force_image_download"
    t.decimal "progress", precision: 8, scale: 2
    t.text "log"
    t.text "error_log"
    t.string "email_recipients"
    t.string "input_data"
    t.string "internal_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamable_type"
    t.integer "teamable_id"
    t.string "input_csv_file_file_name"
    t.string "input_csv_file_content_type"
    t.integer "input_csv_file_file_size"
    t.datetime "input_csv_file_updated_at"
    t.string "output_csv_file_file_name"
    t.string "output_csv_file_content_type"
    t.integer "output_csv_file_file_size"
    t.datetime "output_csv_file_updated_at"
    t.string "hash_option_1"
    t.string "hash_option_2"
    t.string "hash_option_3"
    t.jsonb "json_option_1", default: "{}"
    t.jsonb "json_option_2", default: "{}"
    t.jsonb "json_option_3", default: "{}"
    t.string "array_option_1"
    t.string "array_option_2"
    t.string "array_option_3"
    t.jsonb "settings", default: {}
    t.index ["internal_identifier"], name: "index_spree_long_running_jobs_on_internal_identifier"
    t.index ["json_option_1"], name: "index_spree_long_running_jobs_on_json_option_1", using: :gin
    t.index ["json_option_2"], name: "index_spree_long_running_jobs_on_json_option_2", using: :gin
    t.index ["json_option_3"], name: "index_spree_long_running_jobs_on_json_option_3", using: :gin
    t.index ["retailer_id"], name: "index_spree_long_running_jobs_on_retailer_id"
    t.index ["supplier_id"], name: "index_spree_long_running_jobs_on_supplier_id"
    t.index ["teamable_type", "teamable_id"], name: "index_spree_long_running_jobs_on_teamable_type_and_teamable_id"
    t.index ["user_id"], name: "index_spree_long_running_jobs_on_user_id"
  end

  create_table "spree_mapped_shipping_methods", id: :serial, force: :cascade do |t|
    t.string "teamable_type"
    t.integer "teamable_id"
    t.integer "shipping_method_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_method_id"], name: "index_spree_mapped_shipping_methods_on_shipping_method_id"
    t.index ["teamable_type", "teamable_id", "shipping_method_id"], name: "index_on_teamable_and_method_on_mapped_shipping_methods", unique: true
    t.index ["teamable_type", "teamable_id"], name: "index_on_teamable_for_mapped_shipping_methods"
  end

  create_table "spree_option_type_prototypes", id: :serial, force: :cascade do |t|
    t.integer "prototype_id"
    t.integer "option_type_id"
    t.index ["option_type_id"], name: "index_spree_option_type_prototypes_on_option_type_id"
    t.index ["prototype_id", "option_type_id"], name: "index_option_types_prototypes_on_prototype_and_option_type"
  end

  create_table "spree_option_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "presentation", limit: 100
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spree_option_types_on_name"
    t.index ["position"], name: "index_spree_option_types_on_position"
  end

  create_table "spree_option_value_variants", id: :serial, force: :cascade do |t|
    t.integer "variant_id"
    t.integer "option_value_id"
    t.index ["option_value_id"], name: "index_spree_option_value_variants_on_option_value_id"
    t.index ["variant_id", "option_value_id"], name: "index_option_values_variants_on_variant_id_and_option_value_id"
  end

  create_table "spree_option_values", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.string "name"
    t.string "presentation"
    t.integer "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spree_option_values_on_name"
    t.index ["option_type_id"], name: "index_spree_option_values_on_option_type_id"
    t.index ["position"], name: "index_spree_option_values_on_position"
  end

  create_table "spree_order_invoices", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "status"
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.index ["order_id"], name: "index_spree_order_invoices_on_order_id"
  end

  create_table "spree_order_issue_reports", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.text "description"
    t.string "resolution"
    t.text "decline_reason"
    t.decimal "amount_credited"
    t.string "image1_file_name"
    t.string "image1_content_type"
    t.integer "image1_file_size"
    t.datetime "image1_updated_at"
    t.string "image2_file_name"
    t.string "image2_content_type"
    t.integer "image2_file_size"
    t.datetime "image2_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_spree_order_issue_reports_on_order_id"
  end

  create_table "spree_order_promotions", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.integer "promotion_id"
    t.index ["order_id"], name: "index_spree_order_promotions_on_order_id"
    t.index ["promotion_id", "order_id"], name: "index_spree_order_promotions_on_promotion_id_and_order_id"
  end

  create_table "spree_order_risks", id: :serial, force: :cascade do |t|
    t.string "shopify_identifier"
    t.boolean "cause_cancel"
    t.boolean "display"
    t.string "shopify_order_id"
    t.string "message"
    t.string "recommendation"
    t.decimal "score"
    t.string "source"
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_spree_order_risks_on_order_id"
  end

  create_table "spree_orders", id: :serial, force: :cascade do |t|
    t.string "number", limit: 32
    t.decimal "item_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "state"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "user_id"
    t.datetime "completed_at"
    t.integer "bill_address_id"
    t.integer "ship_address_id"
    t.decimal "payment_total", precision: 10, scale: 2, default: "0.0"
    t.string "shipment_state"
    t.string "payment_state"
    t.string "email"
    t.text "special_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency"
    t.string "last_ip_address"
    t.integer "created_by_id"
    t.decimal "shipment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.string "channel", default: "spree"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "item_count", default: 0
    t.integer "approver_id"
    t.datetime "approved_at"
    t.boolean "confirmation_delivered", default: false
    t.boolean "considered_risky", default: false
    t.string "guest_token"
    t.datetime "canceled_at"
    t.integer "canceler_id"
    t.integer "store_id"
    t.integer "state_lock_version", default: 0, null: false
    t.decimal "taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "internal_identifier"
    t.string "supplier_shopify_identifier"
    t.string "retailer_shopify_identifier"
    t.string "shopify_processing_status"
    t.text "shopify_logs"
    t.integer "retailer_shopify_order_number"
    t.string "retailer_shopify_name"
    t.string "retailer_shopify_number"
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.string "customer_email"
    t.string "source"
    t.decimal "total_shipment_cost", precision: 8, scale: 2, default: "0.0"
    t.datetime "archived_at"
    t.text "searchable_attributes"
    t.integer "payment_reminder_count", default: 0
    t.decimal "supplier_discount", default: "0.0"
    t.decimal "hingeto_discount", default: "0.0"
    t.decimal "applied_shipping_discount", default: "0.0"
    t.datetime "auto_paid_at"
    t.datetime "auto_paid_retailer_notified_at"
    t.string "risk_recommendation"
    t.integer "requested_shipping_method_id"
    t.datetime "original_order_date"
    t.string "purchase_order_number"
    t.datetime "sent_via_edi_at"
    t.integer "supplier_shopify_order_number"
    t.integer "supplier_shopify_number"
    t.string "supplier_shopify_order_name"
    t.datetime "shopify_sent_at"
    t.datetime "must_acknowledge_by"
    t.datetime "must_fulfill_by"
    t.datetime "must_cancel_by"
    t.datetime "will_incur_penalty_at"
    t.datetime "fully_refunded_subtotal_at"
    t.datetime "fully_refunded_shipping_at"
    t.datetime "fully_refunded_tax_at"
    t.datetime "fully_refunded_total_at"
    t.integer "auto_payment_attempts", default: 0
    t.datetime "sent_via_sftp_at"
    t.index ["approver_id"], name: "index_spree_orders_on_approver_id"
    t.index ["auto_paid_at"], name: "index_spree_orders_on_auto_paid_at"
    t.index ["bill_address_id"], name: "index_spree_orders_on_bill_address_id"
    t.index ["canceler_id"], name: "index_spree_orders_on_canceler_id"
    t.index ["completed_at"], name: "index_spree_orders_on_completed_at"
    t.index ["confirmation_delivered"], name: "index_spree_orders_on_confirmation_delivered"
    t.index ["considered_risky"], name: "index_spree_orders_on_considered_risky"
    t.index ["created_by_id"], name: "index_spree_orders_on_created_by_id"
    t.index ["guest_token"], name: "index_spree_orders_on_guest_token"
    t.index ["internal_identifier"], name: "index_spree_orders_on_internal_identifier"
    t.index ["number"], name: "index_spree_orders_on_number"
    t.index ["retailer_id"], name: "index_spree_orders_on_retailer_id"
    t.index ["retailer_shopify_name"], name: "index_spree_orders_on_retailer_shopify_name"
    t.index ["retailer_shopify_number"], name: "index_spree_orders_on_retailer_shopify_number"
    t.index ["retailer_shopify_order_number"], name: "index_spree_orders_on_retailer_shopify_order_number"
    t.index ["ship_address_id"], name: "index_spree_orders_on_ship_address_id"
    t.index ["shopify_sent_at"], name: "index_spree_orders_on_shopify_sent_at"
    t.index ["store_id"], name: "index_spree_orders_on_store_id"
    t.index ["supplier_id"], name: "index_spree_orders_on_supplier_id"
    t.index ["supplier_shopify_number"], name: "index_spree_orders_on_supplier_shopify_number"
    t.index ["supplier_shopify_order_name"], name: "index_spree_orders_on_supplier_shopify_order_name"
    t.index ["supplier_shopify_order_number"], name: "index_spree_orders_on_supplier_shopify_order_number"
    t.index ["user_id", "created_by_id"], name: "index_spree_orders_on_user_id_and_created_by_id"
  end

  create_table "spree_payment_capture_events", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.integer "payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_spree_payment_capture_events_on_payment_id"
  end

  create_table "spree_payment_methods", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_on", default: "both"
    t.boolean "auto_capture"
    t.text "preferences"
    t.integer "position", default: 0
    t.index ["id", "type"], name: "index_spree_payment_methods_on_id_and_type"
  end

  create_table "spree_payments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "order_id"
    t.string "source_type"
    t.integer "source_id"
    t.integer "payment_method_id"
    t.string "state"
    t.string "response_code"
    t.string "avs_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.string "cvv_response_code"
    t.string "cvv_response_message"
    t.index ["number"], name: "index_spree_payments_on_number"
    t.index ["order_id"], name: "index_spree_payments_on_order_id"
    t.index ["payment_method_id"], name: "index_spree_payments_on_payment_method_id"
    t.index ["source_id", "source_type"], name: "index_spree_payments_on_source_id_and_source_type"
  end

  create_table "spree_platform_category_options", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "presentation"
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_identifier"], name: "index_spree_platform_category_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_platform_category_options_on_name"
  end

  create_table "spree_platform_color_options", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "presentation"
    t.integer "parent_id"
    t.string "hex_code"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_identifier"], name: "index_spree_platform_color_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_platform_color_options_on_name"
  end

  create_table "spree_platform_features", id: :serial, force: :cascade do |t|
    t.string "plan_name"
    t.string "stripe_plan_identifier"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_platform_size_options", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "presentation"
    t.string "name_1", null: false
    t.string "name_2"
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_identifier"], name: "index_spree_platform_size_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_platform_size_options_on_name"
    t.index ["name_1"], name: "index_spree_platform_size_options_on_name_1"
  end

  create_table "spree_preferences", id: :serial, force: :cascade do |t|
    t.text "value"
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_spree_preferences_on_key", unique: true
  end

  create_table "spree_prices", id: :serial, force: :cascade do |t|
    t.integer "variant_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_spree_prices_on_deleted_at"
    t.index ["variant_id", "currency"], name: "index_spree_prices_on_variant_id_and_currency"
    t.index ["variant_id"], name: "index_spree_prices_on_variant_id"
  end

  create_table "spree_product_export_processes", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "retailer_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "log"
    t.text "error_log"
    t.index ["product_id"], name: "index_spree_product_export_processes_on_product_id"
    t.index ["retailer_id"], name: "index_spree_product_export_processes_on_retailer_id"
  end

  create_table "spree_product_listings", id: :serial, force: :cascade do |t|
    t.integer "retailer_id", null: false
    t.integer "supplier_id", null: false
    t.integer "product_id", null: false
    t.string "aasm_state"
    t.string "style_identifier"
    t.string "shopify_identifier"
    t.string "internal_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "shopify_title"
    t.string "shopify_handle"
    t.index ["internal_identifier"], name: "index_spree_product_listings_on_internal_identifier"
    t.index ["product_id"], name: "index_spree_product_listings_on_product_id"
    t.index ["retailer_id", "supplier_id", "product_id"], name: "index_product_listing_retailer_supplier_product_id", unique: true
    t.index ["retailer_id"], name: "index_spree_product_listings_on_retailer_id"
    t.index ["style_identifier"], name: "index_spree_product_listings_on_style_identifier"
    t.index ["supplier_id"], name: "index_spree_product_listings_on_supplier_id"
  end

  create_table "spree_product_option_types", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "product_id"
    t.integer "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_type_id"], name: "index_spree_product_option_types_on_option_type_id"
    t.index ["position"], name: "index_spree_product_option_types_on_position"
    t.index ["product_id"], name: "index_spree_product_option_types_on_product_id"
  end

  create_table "spree_product_promotion_rules", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "promotion_rule_id"
    t.index ["product_id"], name: "index_products_promotion_rules_on_product_id"
    t.index ["promotion_rule_id", "product_id"], name: "index_products_promotion_rules_on_promotion_rule_and_product"
  end

  create_table "spree_product_properties", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "product_id"
    t.integer "property_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.index ["position"], name: "index_spree_product_properties_on_position"
    t.index ["product_id"], name: "index_product_properties_on_product_id"
    t.index ["property_id"], name: "index_spree_product_properties_on_property_id"
  end

  create_table "spree_products", id: :serial, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.text "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.string "slug"
    t.text "meta_description"
    t.string "meta_keywords"
    t.integer "tax_category_id"
    t.integer "shipping_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "promotionable", default: true
    t.string "meta_title"
    t.datetime "discontinue_on"
    t.integer "supplier_id"
    t.string "shopify_identifier"
    t.string "internal_identifier"
    t.text "image_urls", default: [], array: true
    t.string "shopify_vendor"
    t.string "license_name"
    t.string "shopify_product_type"
    t.string "submission_state"
    t.integer "image_counter", default: 0
    t.datetime "last_updated_image_counter_at"
    t.integer "supplier_category_option_id"
    t.integer "platform_category_option_id"
    t.string "vendor_style_identifier"
    t.string "dsco_identifier"
    t.string "supplier_product_type"
    t.string "supplier_brand_name"
    t.boolean "submission_compliant"
    t.text "submission_compliance_log"
    t.datetime "submission_compliance_status_updated_at"
    t.boolean "marketplace_compliant"
    t.text "marketplace_compliance_log"
    t.datetime "marketplace_compliance_status_updated_at"
    t.text "preferences"
    t.jsonb "settings", default: {}, null: false
    t.jsonb "search_attributes", default: {}, null: false
    t.datetime "search_attributes_updated_at"
    t.index "((search_attributes -> 'category_taxons'::text)) jsonb_path_ops", name: "spree_products_search_attr_category_taxons_gin_idx", using: :gin
    t.index "((search_attributes -> 'license_taxons'::text)) jsonb_path_ops", name: "spree_products_search_attr_license_taxons_gin_idx", using: :gin
    t.index ["available_on"], name: "index_spree_products_on_available_on"
    t.index ["deleted_at"], name: "index_spree_products_on_deleted_at"
    t.index ["discontinue_on"], name: "index_spree_products_on_discontinue_on"
    t.index ["dsco_identifier"], name: "index_spree_products_on_dsco_identifier"
    t.index ["internal_identifier"], name: "index_spree_products_on_internal_identifier"
    t.index ["name"], name: "index_spree_products_on_name"
    t.index ["search_attributes"], name: "spree_products_search_attr_gin_idx", using: :gin
    t.index ["shipping_category_id"], name: "index_spree_products_on_shipping_category_id"
    t.index ["shopify_identifier"], name: "index_spree_products_on_shopify_identifier"
    t.index ["slug"], name: "index_spree_products_on_slug", unique: true
    t.index ["tax_category_id"], name: "index_spree_products_on_tax_category_id"
    t.index ["vendor_style_identifier"], name: "index_spree_products_on_vendor_style_identifier"
  end

  create_table "spree_products_taxons", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "taxon_id"
    t.integer "position"
    t.index ["position"], name: "index_spree_products_taxons_on_position"
    t.index ["product_id"], name: "index_spree_products_taxons_on_product_id"
    t.index ["taxon_id"], name: "index_spree_products_taxons_on_taxon_id"
  end

  create_table "spree_promotion_action_line_items", id: :serial, force: :cascade do |t|
    t.integer "promotion_action_id"
    t.integer "variant_id"
    t.integer "quantity", default: 1
    t.index ["promotion_action_id"], name: "index_spree_promotion_action_line_items_on_promotion_action_id"
    t.index ["variant_id"], name: "index_spree_promotion_action_line_items_on_variant_id"
  end

  create_table "spree_promotion_actions", id: :serial, force: :cascade do |t|
    t.integer "promotion_id"
    t.integer "position"
    t.string "type"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_spree_promotion_actions_on_deleted_at"
    t.index ["id", "type"], name: "index_spree_promotion_actions_on_id_and_type"
    t.index ["promotion_id"], name: "index_spree_promotion_actions_on_promotion_id"
  end

  create_table "spree_promotion_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
  end

  create_table "spree_promotion_rule_taxons", id: :serial, force: :cascade do |t|
    t.integer "taxon_id"
    t.integer "promotion_rule_id"
    t.index ["promotion_rule_id"], name: "index_spree_promotion_rule_taxons_on_promotion_rule_id"
    t.index ["taxon_id"], name: "index_spree_promotion_rule_taxons_on_taxon_id"
  end

  create_table "spree_promotion_rule_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "promotion_rule_id"
    t.index ["promotion_rule_id"], name: "index_promotion_rules_users_on_promotion_rule_id"
    t.index ["user_id", "promotion_rule_id"], name: "index_promotion_rules_users_on_user_id_and_promotion_rule_id"
  end

  create_table "spree_promotion_rules", id: :serial, force: :cascade do |t|
    t.integer "promotion_id"
    t.integer "user_id"
    t.integer "product_group_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.text "preferences"
    t.index ["product_group_id"], name: "index_promotion_rules_on_product_group_id"
    t.index ["promotion_id"], name: "index_spree_promotion_rules_on_promotion_id"
    t.index ["user_id"], name: "index_promotion_rules_on_user_id"
  end

  create_table "spree_promotions", id: :serial, force: :cascade do |t|
    t.string "description"
    t.datetime "expires_at"
    t.datetime "starts_at"
    t.string "name"
    t.string "type"
    t.integer "usage_limit"
    t.string "match_policy", default: "all"
    t.string "code"
    t.boolean "advertise", default: false
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "promotion_category_id"
    t.index ["advertise"], name: "index_spree_promotions_on_advertise"
    t.index ["code"], name: "index_spree_promotions_on_code"
    t.index ["expires_at"], name: "index_spree_promotions_on_expires_at"
    t.index ["id", "type"], name: "index_spree_promotions_on_id_and_type"
    t.index ["promotion_category_id"], name: "index_spree_promotions_on_promotion_category_id"
    t.index ["starts_at"], name: "index_spree_promotions_on_starts_at"
  end

  create_table "spree_properties", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "presentation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spree_properties_on_name"
  end

  create_table "spree_property_prototypes", id: :serial, force: :cascade do |t|
    t.integer "prototype_id"
    t.integer "property_id"
    t.index ["prototype_id", "property_id"], name: "index_properties_prototypes_on_prototype_and_property"
  end

  create_table "spree_prototype_taxons", id: :serial, force: :cascade do |t|
    t.integer "taxon_id"
    t.integer "prototype_id"
    t.index ["prototype_id", "taxon_id"], name: "index_spree_prototype_taxons_on_prototype_id_and_taxon_id"
    t.index ["taxon_id"], name: "index_spree_prototype_taxons_on_taxon_id"
  end

  create_table "spree_prototypes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_refund_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_refund_records", id: :serial, force: :cascade do |t|
    t.integer "refund_id"
    t.string "refund_type"
    t.string "log"
    t.boolean "is_partial"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["refund_id"], name: "index_spree_refund_records_on_refund_id"
  end

  create_table "spree_refunds", id: :serial, force: :cascade do |t|
    t.integer "payment_id"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "refund_reason_id"
    t.integer "reimbursement_id"
    t.index ["refund_reason_id"], name: "index_refunds_on_refund_reason_id"
  end

  create_table "spree_reimbursement_credits", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "reimbursement_id"
    t.integer "creditable_id"
    t.string "creditable_type"
  end

  create_table "spree_reimbursement_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.index ["type"], name: "index_spree_reimbursement_types_on_type"
  end

  create_table "spree_reimbursements", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "reimbursement_status"
    t.integer "customer_return_id"
    t.integer "order_id"
    t.decimal "total", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_return_id"], name: "index_spree_reimbursements_on_customer_return_id"
    t.index ["order_id"], name: "index_spree_reimbursements_on_order_id"
  end

  create_table "spree_reseller_agreements", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.string "signature_request_identifier"
    t.string "supplier_signer_identifier"
    t.string "retailer_signer_identifier"
    t.string "sign_status"
    t.string "product_ids", default: [], array: true
    t.string "variant_ids", default: [], array: true
    t.datetime "supplier_signed_at"
    t.datetime "retailer_signed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_reseller_agreements_on_retailer_id"
    t.index ["retailer_signer_identifier"], name: "index_spree_reseller_agreements_on_retailer_signer_identifier"
    t.index ["supplier_id"], name: "index_spree_reseller_agreements_on_supplier_id"
    t.index ["supplier_signer_identifier"], name: "index_spree_reseller_agreements_on_supplier_signer_identifier"
  end

  create_table "spree_retail_connections", id: :serial, force: :cascade do |t|
    t.integer "retailer_id", null: false
    t.integer "supplier_id", null: false
    t.boolean "auto_charge_orders", default: false
    t.string "ecommerce_platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_retail_connections_on_retailer_id"
    t.index ["supplier_id", "retailer_id"], name: "index_spree_retail_connections_on_supplier_id_and_retailer_id", unique: true
    t.index ["supplier_id"], name: "index_spree_retail_connections_on_supplier_id"
  end

  create_table "spree_retailer_credits", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.decimal "by_supplier"
    t.decimal "by_hingeto"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_retailer_credits_on_retailer_id"
  end

  create_table "spree_retailer_inventories", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.jsonb "inventory", default: "{}", null: false
    t.datetime "last_generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_retailer_inventories_on_retailer_id", unique: true
  end

  create_table "spree_retailer_order_reports", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.integer "supplier_id"
    t.string "source"
    t.datetime "report_generated_at"
    t.integer "num_of_orders_last_30_days"
    t.integer "num_of_orders_last_60_days"
    t.integer "num_of_orders_last_90_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_retailer_order_reports_on_retailer_id"
    t.index ["supplier_id"], name: "index_spree_retailer_order_reports_on_supplier_id"
  end

  create_table "spree_retailer_platform_features", id: :serial, force: :cascade do |t|
    t.string "plan_name"
    t.string "stripe_plan_identifier"
    t.jsonb "settings", default: {}, null: false
    t.boolean "active"
    t.datetime "expire_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_retailer_referrals", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "string"
    t.string "url"
    t.string "email"
    t.string "image_url"
    t.boolean "has_relationship"
    t.integer "spree_supplier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spree_supplier_id"], name: "index_spree_retailer_referrals_on_spree_supplier_id"
  end

  create_table "spree_retailers", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email", null: false
    t.string "ecommerce_platform"
    t.string "internal_identifier"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "website"
    t.string "phone_number"
    t.string "primary_country"
    t.string "tax_identifier_type"
    t.string "encrypted_tax_identifier"
    t.string "encrypted_tax_identifier_iv"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shopify_url"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "zipcode"
    t.string "state"
    t.string "country"
    t.string "phone"
    t.integer "legal_entity_address_id"
    t.integer "shipping_address_id"
    t.string "shop_owner"
    t.string "domain"
    t.string "plan_name"
    t.string "plan_display_name"
    t.boolean "disable_payments"
    t.string "default_location_shopify_identifier"
    t.boolean "order_auto_payment"
    t.boolean "can_view_supplier_name", default: false
    t.boolean "can_view_brand_name", default: false
    t.jsonb "settings", default: {}
    t.integer "default_us_shipping_method_id"
    t.integer "default_canada_shipping_method_id"
    t.integer "default_rest_of_world_shipping_method_id"
    t.datetime "hingeto_fulfillment_service_created_at"
    t.datetime "shopify_management_switched_to_hingeto_at"
    t.datetime "last_synced_shopify_events_at"
    t.datetime "last_synced_shopify_products_at"
    t.datetime "last_synced_shopify_orders_at"
    t.datetime "last_processed_shopify_events_at"
    t.datetime "access_granted_at"
    t.datetime "auto_payment_set_at"
    t.datetime "completed_onboarding_at"
    t.string "current_stripe_customer_identifier"
    t.string "current_stripe_subscription_identifier"
    t.string "current_stripe_subscription_started_at"
    t.string "current_stripe_plan_identifier"
    t.string "current_stripe_customer_email"
    t.datetime "scheduled_onboarding_at"
    t.datetime "onboarding_session_at"
    t.string "current_shopify_subscription_identifier"
    t.string "unsubscribe_hash"
    t.text "unsubscribe", default: [], array: true
    t.boolean "has_product_listing"
    t.integer "remaining_trial_time", default: 1209600, null: false
    t.datetime "trial_started_on"
    t.string "app_name"
    t.index ["email"], name: "index_spree_retailers_on_email"
    t.index ["internal_identifier"], name: "index_spree_retailers_on_internal_identifier", unique: true
    t.index ["shopify_url"], name: "index_spree_retailers_on_shopify_url"
    t.index ["slug"], name: "index_spree_retailers_on_slug", unique: true
  end

  create_table "spree_return_authorization_reasons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.boolean "mutable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_return_authorizations", id: :serial, force: :cascade do |t|
    t.string "number"
    t.string "state"
    t.integer "order_id"
    t.text "memo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "stock_location_id"
    t.integer "return_authorization_reason_id"
    t.index ["return_authorization_reason_id"], name: "index_return_authorizations_on_return_authorization_reason_id"
  end

  create_table "spree_return_items", id: :serial, force: :cascade do |t|
    t.integer "return_authorization_id"
    t.integer "inventory_unit_id"
    t.integer "exchange_variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "pre_tax_amount", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "included_tax_total", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 12, scale: 4, default: "0.0", null: false
    t.string "reception_status"
    t.string "acceptance_status"
    t.integer "customer_return_id"
    t.integer "reimbursement_id"
    t.integer "exchange_inventory_unit_id"
    t.text "acceptance_status_errors"
    t.integer "preferred_reimbursement_type_id"
    t.integer "override_reimbursement_type_id"
    t.boolean "resellable", default: true, null: false
    t.index ["customer_return_id"], name: "index_return_items_on_customer_return_id"
    t.index ["exchange_inventory_unit_id"], name: "index_spree_return_items_on_exchange_inventory_unit_id"
  end

  create_table "spree_role_users", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["role_id"], name: "index_spree_role_users_on_role_id"
    t.index ["user_id"], name: "index_spree_role_users_on_user_id"
  end

  create_table "spree_roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_spree_roles_on_name"
  end

  create_table "spree_selling_authorities", id: :serial, force: :cascade do |t|
    t.integer "retailer_id"
    t.string "permittable_type"
    t.integer "permittable_id"
    t.string "permission"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permittable_type", "permittable_id"], name: "index_on_permittable_type_id"
    t.index ["retailer_id", "permittable_id", "permittable_type"], name: "index_spree_selling_authorities_on_retailer_and_permittable", unique: true
    t.index ["retailer_id"], name: "index_spree_selling_authorities_on_retailer_id"
  end

  create_table "spree_sftp_credentials", id: :serial, force: :cascade do |t|
    t.string "teamable_type", null: false
    t.integer "teamable_id", null: false
    t.string "name"
    t.text "description"
    t.string "encrypted_server_url"
    t.string "encrypted_server_url_iv"
    t.string "encrypted_username"
    t.string "encrypted_username_iv"
    t.string "encrypted_password"
    t.string "encrypted_password_iv"
    t.string "encrypted_proxy_url"
    t.string "encrypted_proxy_url_iv"
    t.integer "port"
    t.string "root_path"
    t.string "export_order_path"
    t.string "import_order_path"
    t.string "export_asn_path"
    t.string "import_asn_path"
    t.string "export_inventory_path"
    t.string "import_inventory_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teamable_type", "teamable_id"], name: "index_on_teamable_for_sftp_credentials"
  end

  create_table "spree_shipments", id: :serial, force: :cascade do |t|
    t.string "tracking"
    t.string "number"
    t.decimal "cost", precision: 10, scale: 2, default: "0.0"
    t.datetime "shipped_at"
    t.integer "order_id"
    t.integer "address_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock_location_id"
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "promo_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "pre_tax_amount", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "non_taxable_adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "per_item_cost", precision: 8, scale: 2, default: "0.0"
    t.integer "courier_id"
    t.integer "shipping_method_id"
    t.datetime "fulfilled_at"
    t.datetime "cancelled_at"
    t.datetime "invalid_fulfilled_at"
    t.index ["address_id"], name: "index_spree_shipments_on_address_id"
    t.index ["number"], name: "index_shipments_on_number"
    t.index ["order_id"], name: "index_spree_shipments_on_order_id"
    t.index ["stock_location_id"], name: "index_spree_shipments_on_stock_location_id"
  end

  create_table "spree_shipping_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supplier_id"
    t.index ["name"], name: "index_spree_shipping_categories_on_name"
  end

  create_table "spree_shipping_method_categories", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id", null: false
    t.integer "shipping_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_category_id", "shipping_method_id"], name: "unique_spree_shipping_method_categories", unique: true
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_categories_on_shipping_method_id"
  end

  create_table "spree_shipping_method_zones", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id"
    t.integer "zone_id"
  end

  create_table "spree_shipping_methods", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "display_on"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tracking_url"
    t.string "admin_name"
    t.integer "tax_category_id"
    t.string "code"
    t.integer "supplier_id"
    t.string "courier_name"
    t.string "service_name"
    t.string "service_code"
    t.integer "courier_id"
    t.boolean "active"
    t.index ["deleted_at"], name: "index_spree_shipping_methods_on_deleted_at"
    t.index ["tax_category_id"], name: "index_spree_shipping_methods_on_tax_category_id"
  end

  create_table "spree_shipping_rates", id: :serial, force: :cascade do |t|
    t.integer "shipment_id"
    t.integer "shipping_method_id"
    t.boolean "selected", default: false
    t.decimal "cost", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tax_rate_id"
    t.index ["selected"], name: "index_spree_shipping_rates_on_selected"
    t.index ["shipment_id", "shipping_method_id"], name: "spree_shipping_rates_join_index", unique: true
    t.index ["tax_rate_id"], name: "index_spree_shipping_rates_on_tax_rate_id"
  end

  create_table "spree_shipping_zone_eligibilities", id: :serial, force: :cascade do |t|
    t.integer "supplier_id"
    t.integer "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id", "zone_id"], name: "index_spree_shipping_zone_eligibilities_on_supplier_zone_id"
    t.index ["supplier_id"], name: "index_spree_shipping_zone_eligibilities_on_supplier_id"
    t.index ["zone_id"], name: "index_spree_shipping_zone_eligibilities_on_zone_id"
  end

  create_table "spree_shopify_credentials", id: :serial, force: :cascade do |t|
    t.string "store_url"
    t.string "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamable_type"
    t.integer "teamable_id"
    t.datetime "uninstalled_at"
    t.index ["teamable_type", "teamable_id"], name: "index_on_teamable_for_shopify_credentials"
  end

  create_table "spree_special_variant_costs", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.integer "retailer_id"
    t.string "sku", null: false
    t.string "msrp_currency", default: "USD"
    t.decimal "msrp", null: false
    t.string "cost_currency", default: "USD"
    t.decimal "cost", null: false
    t.string "minimum_advertised_price_currency", default: "USD"
    t.decimal "minimum_advertised_price"
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retailer_id"], name: "index_spree_special_variant_costs_on_retailer_id"
    t.index ["supplier_id", "retailer_id", "sku"], name: "index_on_spree_special_variant_costs_on_supplier_retailer_sku", unique: true
    t.index ["supplier_id"], name: "index_spree_special_variant_costs_on_supplier_id"
  end

  create_table "spree_state_changes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "previous_state"
    t.integer "stateful_id"
    t.integer "user_id"
    t.string "stateful_type"
    t.string "next_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stateful_id", "stateful_type"], name: "index_spree_state_changes_on_stateful_id_and_stateful_type"
  end

  create_table "spree_states", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "abbr"
    t.integer "country_id"
    t.datetime "updated_at"
    t.index ["country_id"], name: "index_spree_states_on_country_id"
  end

  create_table "spree_stock_item_trackings", id: :serial, force: :cascade do |t|
    t.integer "stock_item_id"
    t.integer "product_id"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_spree_stock_item_trackings_on_product_id"
    t.index ["stock_item_id"], name: "index_spree_stock_item_trackings_on_stock_item_id"
  end

  create_table "spree_stock_items", id: :serial, force: :cascade do |t|
    t.integer "stock_location_id"
    t.integer "variant_id"
    t.integer "count_on_hand", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "backorderable", default: false
    t.datetime "deleted_at"
    t.index ["backorderable"], name: "index_spree_stock_items_on_backorderable"
    t.index ["deleted_at"], name: "index_spree_stock_items_on_deleted_at"
    t.index ["stock_location_id", "variant_id"], name: "stock_item_by_loc_and_var_id"
    t.index ["stock_location_id"], name: "index_spree_stock_items_on_stock_location_id"
    t.index ["variant_id"], name: "index_spree_stock_items_on_variant_id"
  end

  create_table "spree_stock_locations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default", default: false, null: false
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.integer "state_id"
    t.string "state_name"
    t.integer "country_id"
    t.string "zipcode"
    t.string "phone"
    t.boolean "active", default: true
    t.boolean "backorderable_default", default: false
    t.boolean "propagate_all_variants", default: true
    t.string "admin_name"
    t.integer "supplier_id"
    t.index ["active"], name: "index_spree_stock_locations_on_active"
    t.index ["backorderable_default"], name: "index_spree_stock_locations_on_backorderable_default"
    t.index ["country_id"], name: "index_spree_stock_locations_on_country_id"
    t.index ["propagate_all_variants"], name: "index_spree_stock_locations_on_propagate_all_variants"
    t.index ["state_id"], name: "index_spree_stock_locations_on_state_id"
    t.index ["supplier_id"], name: "index_spree_stock_locations_on_supplier_id"
  end

  create_table "spree_stock_movements", id: :serial, force: :cascade do |t|
    t.integer "stock_item_id"
    t.integer "quantity", default: 0
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "originator_type"
    t.integer "originator_id"
    t.index ["stock_item_id"], name: "index_spree_stock_movements_on_stock_item_id"
  end

  create_table "spree_stock_transfers", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "reference"
    t.integer "source_location_id"
    t.integer "destination_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.index ["destination_location_id"], name: "index_spree_stock_transfers_on_destination_location_id"
    t.index ["number"], name: "index_spree_stock_transfers_on_number"
    t.index ["source_location_id"], name: "index_spree_stock_transfers_on_source_location_id"
  end

  create_table "spree_store_credit_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_store_credit_events", id: :serial, force: :cascade do |t|
    t.integer "store_credit_id", null: false
    t.string "action", null: false
    t.decimal "amount", precision: 8, scale: 2
    t.string "authorization_code", null: false
    t.decimal "user_total_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "originator_id"
    t.string "originator_type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["originator_id", "originator_type"], name: "spree_store_credit_events_originator"
    t.index ["store_credit_id"], name: "index_spree_store_credit_events_on_store_credit_id"
  end

  create_table "spree_store_credit_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority"], name: "index_spree_store_credit_types_on_priority"
  end

  create_table "spree_store_credits", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "category_id"
    t.integer "created_by_id"
    t.decimal "amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "amount_used", precision: 8, scale: 2, default: "0.0", null: false
    t.text "memo"
    t.datetime "deleted_at"
    t.string "currency"
    t.decimal "amount_authorized", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "originator_id"
    t.string "originator_type"
    t.integer "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_spree_store_credits_on_deleted_at"
    t.index ["originator_id", "originator_type"], name: "spree_store_credits_originator"
    t.index ["type_id"], name: "index_spree_store_credits_on_type_id"
    t.index ["user_id"], name: "index_spree_store_credits_on_user_id"
  end

  create_table "spree_stores", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.text "meta_description"
    t.text "meta_keywords"
    t.string "seo_title"
    t.string "mail_from_address"
    t.string "default_currency"
    t.string "code"
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_spree_stores_on_code"
    t.index ["default"], name: "index_spree_stores_on_default"
    t.index ["url"], name: "index_spree_stores_on_url"
  end

  create_table "spree_supplier_category_options", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.string "name", null: false
    t.string "presentation"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "platform_category_option_id"
    t.index ["internal_identifier"], name: "index_spree_supplier_category_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_supplier_category_options_on_name"
    t.index ["supplier_id", "name"], name: "index_spree_supplier_category_options_on_supplier_id_and_name", unique: true
    t.index ["supplier_id"], name: "index_spree_supplier_category_options_on_supplier_id"
  end

  create_table "spree_supplier_color_options", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.string "name", null: false
    t.string "presentation"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "platform_color_option_id"
    t.index ["internal_identifier"], name: "index_spree_supplier_color_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_supplier_color_options_on_name"
    t.index ["supplier_id", "name"], name: "index_spree_supplier_color_options_on_supplier_id_and_name", unique: true
    t.index ["supplier_id"], name: "index_spree_supplier_color_options_on_supplier_id"
  end

  create_table "spree_supplier_license_options", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.string "name", null: false
    t.string "presentation"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "last_updated_licenses_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["internal_identifier"], name: "index_spree_supplier_license_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_supplier_license_options_on_name"
    t.index ["supplier_id"], name: "index_spree_supplier_license_options_on_supplier_id"
  end

  create_table "spree_supplier_platform_features", id: :serial, force: :cascade do |t|
    t.string "plan_name"
    t.string "stripe_plan_identifier"
    t.jsonb "settings", default: {}, null: false
    t.boolean "active"
    t.datetime "expire_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_supplier_referrals", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "string"
    t.string "url"
    t.string "email"
    t.string "image_url"
    t.boolean "has_relationship"
    t.integer "spree_retailer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spree_retailer_id"], name: "index_spree_supplier_referrals_on_spree_retailer_id"
  end

  create_table "spree_supplier_size_options", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.string "name", null: false
    t.string "presentation"
    t.integer "position", default: 0
    t.string "internal_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "platform_size_option_id"
    t.index ["internal_identifier"], name: "index_spree_supplier_size_options_on_internal_identifier"
    t.index ["name"], name: "index_spree_supplier_size_options_on_name"
    t.index ["supplier_id"], name: "index_spree_supplier_size_options_on_supplier_id"
  end

  create_table "spree_suppliers", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email", null: false
    t.string "ecommerce_platform"
    t.string "internal_identifier"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "website"
    t.string "phone_number"
    t.string "primary_country"
    t.string "tax_identifier_type"
    t.string "encrypted_tax_identifier"
    t.string "encrypted_tax_identifier_iv"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shopify_url"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "zipcode"
    t.string "state"
    t.string "country"
    t.string "phone"
    t.string "shop_owner"
    t.string "domain"
    t.string "plan_name"
    t.string "plan_display_name"
    t.string "pseudonym"
    t.boolean "allow_free_shipping_for_samples", default: true
    t.integer "num_free_shipping_for_samples_allowed", default: 3
    t.boolean "allow_order_issue_reporting", default: true
    t.string "instance_type"
    t.float "default_markup_percentage"
    t.datetime "last_updated_categories_at"
    t.string "dsco_identifier"
    t.datetime "last_updated_colors_at"
    t.datetime "last_updated_sizes_at"
    t.string "display_name"
    t.string "shopify_product_unique_identifier", default: "sku"
    t.string "brand_short_code"
    t.string "logo_file_name"
    t.string "logo_content_type"
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.jsonb "settings", default: {}
    t.string "internal_vendor_number"
    t.string "edi_identifier"
    t.string "edi_van_name"
    t.string "edi_contact_full_name"
    t.string "edi_contact_email"
    t.string "edi_contact_phone_number"
    t.boolean "transmit_orders_to_supplier_via_edi", default: false
    t.datetime "last_synced_shopify_events_at"
    t.datetime "last_synced_shopify_products_at"
    t.datetime "last_synced_shopify_orders_at"
    t.datetime "last_processed_shopify_events_at"
    t.datetime "access_granted_at"
    t.datetime "completed_onboarding_at"
    t.string "current_stripe_customer_identifier"
    t.string "current_stripe_subscription_identifier"
    t.string "current_stripe_subscription_started_at"
    t.string "current_stripe_plan_identifier"
    t.string "current_stripe_customer_email"
    t.datetime "scheduled_onboarding_at"
    t.datetime "onboarding_session_at"
    t.string "current_shopify_subscription_identifier"
    t.index ["email"], name: "index_spree_suppliers_on_email"
    t.index ["internal_identifier"], name: "index_spree_suppliers_on_internal_identifier", unique: true
    t.index ["shopify_url"], name: "index_spree_suppliers_on_shopify_url"
    t.index ["slug"], name: "index_spree_suppliers_on_slug", unique: true
  end

  create_table "spree_taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_spree_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "spree_taggings_idx", unique: true
    t.index ["tag_id"], name: "index_spree_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "spree_taggings_idy"
    t.index ["taggable_id"], name: "index_spree_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_spree_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_spree_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_spree_taggings_on_tagger_id"
  end

  create_table "spree_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_spree_tags_on_name", unique: true
  end

  create_table "spree_tax_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "is_default", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tax_code"
    t.index ["deleted_at"], name: "index_spree_tax_categories_on_deleted_at"
    t.index ["is_default"], name: "index_spree_tax_categories_on_is_default"
  end

  create_table "spree_tax_rates", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 5
    t.integer "zone_id"
    t.integer "tax_category_id"
    t.boolean "included_in_price", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "show_rate_in_label", default: true
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_spree_tax_rates_on_deleted_at"
    t.index ["included_in_price"], name: "index_spree_tax_rates_on_included_in_price"
    t.index ["show_rate_in_label"], name: "index_spree_tax_rates_on_show_rate_in_label"
    t.index ["tax_category_id"], name: "index_spree_tax_rates_on_tax_category_id"
    t.index ["zone_id"], name: "index_spree_tax_rates_on_zone_id"
  end

  create_table "spree_taxon_groupings", id: :serial, force: :cascade do |t|
    t.integer "taxon_id"
    t.integer "grouping_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grouping_id"], name: "index_spree_taxon_groupings_on_grouping_id"
    t.index ["taxon_id"], name: "index_spree_taxon_groupings_on_taxon_id"
  end

  create_table "spree_taxonomies", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.datetime "discontinue_on"
    t.datetime "deleted_at"
    t.index ["position"], name: "index_spree_taxonomies_on_position"
  end

  create_table "spree_taxons", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "name", null: false
    t.string "permalink"
    t.integer "taxonomy_id"
    t.integer "lft"
    t.integer "rgt"
    t.string "icon_file_name"
    t.string "icon_content_type"
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "meta_title"
    t.string "meta_description"
    t.string "meta_keywords"
    t.integer "depth"
    t.string "outer_banner_file_name"
    t.string "outer_banner_content_type"
    t.integer "outer_banner_file_size"
    t.datetime "outer_banner_updated_at"
    t.string "inner_banner_file_name"
    t.string "inner_banner_content_type"
    t.integer "inner_banner_file_size"
    t.datetime "inner_banner_updated_at"
    t.datetime "discontinue_on"
    t.datetime "deleted_at"
    t.integer "google_category_id"
    t.string "google_category_nested_string"
    t.string "mini_identifier"
    t.string "slug"
    t.string "display_name"
    t.boolean "master_license"
    t.boolean "master_category"
    t.boolean "visible"
    t.integer "supplier_id"
    t.integer "retailer_id"
    t.index ["google_category_id"], name: "index_spree_taxons_on_google_category_id"
    t.index ["google_category_nested_string"], name: "index_spree_taxons_on_google_category_nested_string"
    t.index ["lft"], name: "index_spree_taxons_on_lft"
    t.index ["mini_identifier"], name: "index_spree_taxons_on_mini_identifier", unique: true
    t.index ["name"], name: "index_spree_taxons_on_name"
    t.index ["parent_id"], name: "index_taxons_on_parent_id"
    t.index ["permalink"], name: "index_taxons_on_permalink"
    t.index ["position"], name: "index_spree_taxons_on_position"
    t.index ["rgt"], name: "index_spree_taxons_on_rgt"
    t.index ["slug"], name: "index_spree_taxons_on_slug", unique: true
    t.index ["taxonomy_id"], name: "index_taxons_on_taxonomy_id"
  end

  create_table "spree_team_members", id: :serial, force: :cascade do |t|
    t.string "teamable_type"
    t.integer "teamable_id"
    t.integer "user_id"
    t.integer "role_id"
    t.string "internal_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_spree_team_members_on_role_id"
    t.index ["teamable_type", "teamable_id"], name: "index_spree_team_members_on_teamable_type_and_teamable_id"
    t.index ["user_id"], name: "index_spree_team_members_on_user_id"
  end

  create_table "spree_trackers", id: :serial, force: :cascade do |t|
    t.string "analytics_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_spree_trackers_on_active"
  end

  create_table "spree_users", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", limit: 128
    t.string "password_salt", limit: 128
    t.string "email"
    t.string "remember_token"
    t.string "persistence_token"
    t.string "reset_password_token"
    t.string "perishable_token"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "login"
    t.integer "ship_address_id"
    t.integer "bill_address_id"
    t.string "authentication_token"
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spree_api_key", limit: 48
    t.datetime "remember_created_at"
    t.datetime "deleted_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.boolean "using_temporary_password", default: false
    t.string "shopify_slug"
    t.string "shopify_url"
    t.integer "default_team_member_id"
    t.index ["bill_address_id"], name: "index_spree_users_on_bill_address_id"
    t.index ["deleted_at"], name: "index_spree_users_on_deleted_at"
    t.index ["email", "shopify_slug"], name: "index_spree_users_on_email_and_shopify_slug", unique: true
    t.index ["email", "shopify_url"], name: "index_spree_users_on_email_and_shopify_url", unique: true
    t.index ["ship_address_id"], name: "index_spree_users_on_ship_address_id"
    t.index ["spree_api_key"], name: "index_spree_users_on_spree_api_key"
  end

  create_table "spree_variant_costs", id: :serial, force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.string "sku", null: false
    t.string "msrp_currency", default: "USD"
    t.decimal "msrp", null: false
    t.string "cost_currency", default: "USD"
    t.decimal "cost", null: false
    t.string "minimum_advertised_price_currency", default: "USD"
    t.decimal "minimum_advertised_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id", "sku"], name: "index_on_spree_variant_costs_on_supplier_retailer_sku", unique: true
    t.index ["supplier_id"], name: "index_spree_variant_costs_on_supplier_id"
  end

  create_table "spree_variant_listings", id: :serial, force: :cascade do |t|
    t.integer "retailer_id", null: false
    t.integer "supplier_id", null: false
    t.integer "variant_id", null: false
    t.integer "storefront_id"
    t.string "style_identifier"
    t.string "identifier1"
    t.string "identifier2"
    t.string "identifier3"
    t.string "internal_sku"
    t.string "shopify_identifier"
    t.string "internal_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "product_listing_id"
    t.datetime "shopify_management_switched_to_hingeto_at"
    t.index ["internal_identifier"], name: "index_spree_variant_listings_on_internal_identifier"
    t.index ["product_listing_id"], name: "index_spree_variant_listings_on_product_listing_id"
    t.index ["retailer_id", "supplier_id", "variant_id"], name: "index_retailer_supplier_variant_id", unique: true
    t.index ["retailer_id"], name: "index_spree_variant_listings_on_retailer_id"
    t.index ["supplier_id"], name: "index_spree_variant_listings_on_supplier_id"
    t.index ["variant_id"], name: "index_spree_variant_listings_on_variant_id"
  end

  create_table "spree_variants", id: :serial, force: :cascade do |t|
    t.string "sku", default: "", null: false
    t.decimal "weight", precision: 8, scale: 2, default: "0.0"
    t.decimal "height", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "depth", precision: 8, scale: 2
    t.datetime "deleted_at"
    t.boolean "is_master", default: false
    t.integer "product_id"
    t.decimal "cost_price", precision: 10, scale: 2
    t.integer "position"
    t.string "cost_currency"
    t.boolean "track_inventory", default: true
    t.integer "tax_category_id"
    t.datetime "updated_at", null: false
    t.datetime "discontinue_on"
    t.datetime "created_at", null: false
    t.integer "supplier_id"
    t.string "shopify_identifier"
    t.string "internal_identifier"
    t.decimal "msrp_price", precision: 8, scale: 2
    t.string "msrp_currency", default: "USD"
    t.string "supplier_color_value"
    t.string "supplier_size_value"
    t.string "supplier_category_value"
    t.string "original_supplier_sku"
    t.text "image_urls", default: [], array: true
    t.string "barcode"
    t.string "upc"
    t.string "weight_unit"
    t.decimal "map_price"
    t.string "gtin"
    t.string "dsco_identifier"
    t.boolean "submission_compliant"
    t.text "submission_compliance_log"
    t.datetime "submission_compliance_status_updated_at"
    t.boolean "marketplace_compliant"
    t.text "marketplace_compliance_log"
    t.datetime "marketplace_compliance_status_updated_at"
    t.integer "supplier_color_option_id"
    t.integer "platform_color_option_id"
    t.integer "supplier_size_option_id"
    t.integer "platform_size_option_id"
    t.string "price_management", default: "shopify"
    t.string "platform_supplier_sku"
    t.index ["barcode"], name: "index_spree_variants_on_barcode"
    t.index ["deleted_at"], name: "index_spree_variants_on_deleted_at"
    t.index ["discontinue_on"], name: "index_spree_variants_on_discontinue_on"
    t.index ["dsco_identifier"], name: "index_spree_variants_on_dsco_identifier"
    t.index ["gtin"], name: "index_spree_variants_on_gtin"
    t.index ["internal_identifier"], name: "index_spree_variants_on_internal_identifier"
    t.index ["is_master"], name: "index_spree_variants_on_is_master"
    t.index ["original_supplier_sku"], name: "index_spree_variants_on_original_supplier_sku"
    t.index ["platform_supplier_sku"], name: "index_spree_variants_on_platform_supplier_sku"
    t.index ["position"], name: "index_spree_variants_on_position"
    t.index ["product_id"], name: "index_spree_variants_on_product_id"
    t.index ["shopify_identifier"], name: "index_spree_variants_on_shopify_identifier"
    t.index ["sku"], name: "index_spree_variants_on_sku"
    t.index ["tax_category_id"], name: "index_spree_variants_on_tax_category_id"
    t.index ["track_inventory"], name: "index_spree_variants_on_track_inventory"
    t.index ["upc"], name: "index_spree_variants_on_upc"
  end

  create_table "spree_webhooks", id: :serial, force: :cascade do |t|
    t.string "address"
    t.string "topic"
    t.string "shopify_identifier"
    t.integer "teamable_id"
    t.string "teamable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teamable_type", "teamable_id"], name: "index_spree_webhooks_on_teamable_type_and_teamable_id"
  end

  create_table "spree_woo_credentials", force: :cascade do |t|
    t.string "store_url"
    t.string "consumer_key"
    t.string "consumer_secret"
    t.string "version"
    t.string "teamable_type"
    t.integer "wooteamable_id"
    t.datetime "uninstalled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "spree_zone_members", id: :serial, force: :cascade do |t|
    t.string "zoneable_type"
    t.integer "zoneable_id"
    t.integer "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id"], name: "index_spree_zone_members_on_zone_id"
    t.index ["zoneable_id", "zoneable_type"], name: "index_spree_zone_members_on_zoneable_id_and_zoneable_type"
  end

  create_table "spree_zones", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "default_tax", default: false
    t.integer "zone_members_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.index ["default_tax"], name: "index_spree_zones_on_default_tax"
    t.index ["kind"], name: "index_spree_zones_on_kind"
  end

  create_table "stripe_cards", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.integer "stripe_customer_id"
    t.string "card_identifier"
    t.string "address_city"
    t.string "address_country"
    t.string "address_line1"
    t.string "address_line1_check"
    t.string "address_line2"
    t.string "address_state"
    t.string "address_zip"
    t.string "address_zip_check"
    t.string "brand"
    t.string "country"
    t.string "customer_identifier"
    t.string "cvc_check"
    t.string "dynamic_last4"
    t.integer "exp_month"
    t.integer "exp_year"
    t.string "fingerprint"
    t.string "funding"
    t.string "last4"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_stripe_cards_on_stripe_customer_id"
  end

  create_table "stripe_customers", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "strippable_type"
    t.integer "strippable_id"
    t.string "customer_identifier"
    t.integer "account_balance"
    t.string "currency"
    t.string "default_source"
    t.boolean "delinquent"
    t.string "description"
    t.string "email"
    t.jsonb "discount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strippable_type", "strippable_id"], name: "index_stripe_customers_on_strippable_type_and_strippable_id"
  end

  create_table "stripe_events", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "event_identifier"
    t.datetime "event_created"
    t.string "stripe_eventable_type"
    t.integer "stripe_eventable_id"
    t.jsonb "event_object"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_eventable_type", "stripe_eventable_id"], name: "index_on_type_and_id"
  end

  create_table "stripe_invoices", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.integer "stripe_customer_id"
    t.string "invoice_identifier"
    t.integer "amount_due"
    t.integer "application_fee"
    t.integer "attempt_count"
    t.boolean "attempted"
    t.string "charge_identifier"
    t.boolean "closed"
    t.string "currency"
    t.string "customer_identifier"
    t.datetime "date"
    t.string "description"
    t.jsonb "discount"
    t.boolean "forgiven"
    t.datetime "next_payment_attempt"
    t.boolean "paid"
    t.datetime "period_end"
    t.datetime "period_start"
    t.string "receipt_number"
    t.integer "starting_balance"
    t.string "statement_descriptor"
    t.string "subscription_identifier"
    t.integer "subtotal"
    t.integer "total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_stripe_invoices_on_stripe_customer_id"
  end

  create_table "stripe_plans", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "plan_identifier"
    t.string "name"
    t.integer "amount"
    t.string "currency"
    t.string "interval"
    t.integer "interval_count"
    t.string "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stripe_subscriptions", id: :serial, force: :cascade do |t|
    t.string "internal_identifier"
    t.string "subscription_identifier"
    t.string "plan_identifier"
    t.string "customer_identifier"
    t.integer "stripe_plan_id"
    t.integer "stripe_customer_id"
    t.boolean "cancel_at_period_end"
    t.datetime "canceled_at"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.integer "quantity"
    t.datetime "start"
    t.datetime "ended_at"
    t.datetime "trial_start"
    t.datetime "trial_end"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_stripe_subscriptions_on_stripe_customer_id"
    t.index ["stripe_plan_id"], name: "index_stripe_subscriptions_on_stripe_plan_id"
  end

  create_table "variant_cost_versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_variant_cost_versions_on_item_type_and_item_id"
  end

  add_foreign_key "spree_featured_banners", "spree_taxons", column: "taxon_id"
  add_foreign_key "spree_order_issue_reports", "spree_orders", column: "order_id"
  add_foreign_key "spree_order_risks", "spree_orders", column: "order_id"
  add_foreign_key "spree_refund_records", "spree_refunds", column: "refund_id"
  add_foreign_key "spree_retailer_credits", "spree_retailers", column: "retailer_id"
  add_foreign_key "spree_retailer_inventories", "spree_retailers", column: "retailer_id"
  add_foreign_key "spree_retailer_referrals", "spree_suppliers"
  add_foreign_key "spree_selling_authorities", "spree_retailers", column: "retailer_id"
  add_foreign_key "spree_shipping_zone_eligibilities", "spree_suppliers", column: "supplier_id"
  add_foreign_key "spree_shipping_zone_eligibilities", "spree_zones", column: "zone_id"
  add_foreign_key "spree_special_variant_costs", "spree_retailers", column: "retailer_id"
  add_foreign_key "spree_special_variant_costs", "spree_suppliers", column: "supplier_id"
  add_foreign_key "spree_stock_item_trackings", "spree_products", column: "product_id"
  add_foreign_key "spree_stock_item_trackings", "spree_stock_items", column: "stock_item_id"
  add_foreign_key "spree_supplier_referrals", "spree_retailers"
  add_foreign_key "spree_taxon_groupings", "spree_groupings", column: "grouping_id"
  add_foreign_key "spree_taxon_groupings", "spree_taxons", column: "taxon_id"
  add_foreign_key "spree_team_members", "spree_roles", column: "role_id"
  add_foreign_key "spree_team_members", "spree_users", column: "user_id"
  add_foreign_key "spree_variant_costs", "spree_suppliers", column: "supplier_id"

  create_view "spree_product_csvs", sql_definition: <<-SQL
      SELECT p.id,
      sup.id AS supplier_id,
      sup.name AS supplier,
      p.name AS product_title,
      p.description,
      p.shopify_vendor,
      p.supplier_brand_name,
      p.vendor_style_identifier,
      v.sku,
      v.original_supplier_sku,
      v.barcode,
      v.gtin,
      v.weight,
      v.weight_unit,
      v.height,
      v.supplier_color_value AS supplier_color,
      spco.name AS hingeto_color,
      v.supplier_size_value AS supplier_size,
      spso.name AS hingeto_size,
      v.supplier_category_value AS supplier_category,
      spcao.name AS hingeto_category,
      array_to_string(v.image_urls, ','::text) AS variant_image,
      array_to_string(p.image_urls, ','::text) AS product_image,
      v.cost_price AS wholesale_cost,
      v.cost_currency,
      v.msrp_price,
      v.msrp_currency,
      v.map_price,
      p.submission_state
     FROM (((((spree_products p
       LEFT JOIN spree_variants v ON ((p.id = v.product_id)))
       LEFT JOIN spree_suppliers sup ON ((p.supplier_id = sup.id)))
       LEFT JOIN spree_platform_color_options spco ON ((v.platform_color_option_id = spco.id)))
       LEFT JOIN spree_platform_size_options spso ON ((v.platform_size_option_id = spso.id)))
       LEFT JOIN spree_platform_category_options spcao ON ((p.platform_category_option_id = spcao.id)));
  SQL
  create_view "spree_variant_cost_csvs", sql_definition: <<-SQL
      SELECT vc.id,
      sup.id AS supplier_id,
      sup.name AS supplier,
      vc.sku,
      vc.msrp,
      vc.cost,
      vc.minimum_advertised_price
     FROM (spree_variant_costs vc
       LEFT JOIN spree_suppliers sup ON ((vc.supplier_id = sup.id)));
  SQL
end
