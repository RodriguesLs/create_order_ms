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

ActiveRecord::Schema[7.2].define(version: 2025_06_15_161811) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "webhook_logs", force: :cascade do |t|
    t.string "order_id"
    t.string "account"
    t.text "payload"
    t.integer "http_status"
    t.boolean "success"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "error_message"
    t.index ["account"], name: "index_webhook_logs_on_account"
    t.index ["order_id"], name: "index_webhook_logs_on_order_id"
  end
end
