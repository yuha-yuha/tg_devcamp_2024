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

ActiveRecord::Schema[7.1].define(version: 2024_08_23_084251) do
  create_table "coupons", force: :cascade do |t|
    t.string "serial_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "impressions", force: :cascade do |t|
    t.integer "product_id"
    t.integer "user_id"
    t.integer "post_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_impressions_on_product_id"
    t.index ["user_id", "product_id"], name: "index_impressions_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_impressions_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "convenience_store_type"
    t.string "store_name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "content"
    t.string "name"
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_products_on_post_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "line_user_id", null: false
    t.string "name"
    t.datetime "coupon_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_user_id"], name: "index_users_on_line_user_id", unique: true
  end

  add_foreign_key "impressions", "products"
  add_foreign_key "impressions", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "products", "posts"
end
