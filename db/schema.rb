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

ActiveRecord::Schema[8.1].define(version: 2026_11_08_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", default: "", null: false
    t.integer "next_sale_number", default: 1, null: false
    t.string "phone"
    t.text "ticket_footer"
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_categories_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_categories_on_account_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address"
    t.datetime "created_at", null: false
    t.string "document_number"
    t.string "email"
    t.string "name", default: "", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id", "document_number"], name: "index_customers_on_account_id_and_document_number", unique: true
    t.index ["account_id"], name: "index_customers_on_account_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.text "note"
    t.integer "payment_method", default: 0, null: false
    t.date "spent_on", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id", "spent_on"], name: "index_expenses_on_account_id_and_spent_on"
    t.index ["account_id"], name: "index_expenses_on_account_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.text "note"
    t.integer "payment_method", default: 0, null: false
    t.bigint "sale_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["sale_id"], name: "index_payments_on_sale_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.decimal "cost_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "min_stock", default: 0, null: false
    t.string "name", default: "", null: false
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.string "sku"
    t.integer "stock", default: 0, null: false
    t.string "unit", default: "unidad", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_products_on_account_id_and_name"
    t.index ["account_id", "sku"], name: "index_products_on_account_id_and_sku", unique: true
    t.index ["account_id"], name: "index_products_on_account_id"
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "unit_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.string "number", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "supplier_id"
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "created_at"], name: "index_purchases_on_account_id_and_created_at"
    t.index ["account_id", "number"], name: "index_purchases_on_account_id_and_number", unique: true
    t.index ["account_id"], name: "index_purchases_on_account_id"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "sale_id", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "unit_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.decimal "discount", precision: 12, scale: 2, default: "0.0", null: false
    t.text "note"
    t.string "number", null: false
    t.integer "payment_method", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "created_at"], name: "index_sales_on_account_id_and_created_at"
    t.index ["account_id", "number"], name: "index_sales_on_account_id_and_number", unique: true
    t.index ["account_id"], name: "index_sales_on_account_id"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "movement_type", default: 0, null: false
    t.integer "new_quantity", default: 0, null: false
    t.text "note"
    t.integer "previous_quantity", default: 0, null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id"
    t.integer "quantity", default: 0, null: false
    t.bigint "sale_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id", "movement_type"], name: "index_stock_movements_on_account_id_and_movement_type"
    t.index ["account_id", "product_id", "created_at"], name: "idx_on_account_id_product_id_created_at_6ec346d83c"
    t.index ["account_id"], name: "index_stock_movements_on_account_id"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["purchase_id"], name: "index_stock_movements_on_purchase_id"
    t.index ["sale_id"], name: "index_stock_movements_on_sale_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", default: "", null: false
    t.string "phone"
    t.string "ruc"
    t.datetime "updated_at", null: false
    t.index ["account_id", "ruc"], name: "index_suppliers_on_account_id_and_ruc", unique: true
    t.index ["account_id"], name: "index_suppliers_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_users_on_account_id_and_email", unique: true
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "categories", "accounts"
  add_foreign_key "customers", "accounts"
  add_foreign_key "expenses", "accounts"
  add_foreign_key "expenses", "users"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "customers"
  add_foreign_key "payments", "sales"
  add_foreign_key "payments", "users"
  add_foreign_key "products", "accounts"
  add_foreign_key "products", "categories"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "accounts"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "purchases", "users"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "accounts"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "users"
  add_foreign_key "stock_movements", "accounts"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "purchases"
  add_foreign_key "stock_movements", "sales"
  add_foreign_key "stock_movements", "users"
  add_foreign_key "suppliers", "accounts"
  add_foreign_key "users", "accounts"
end
