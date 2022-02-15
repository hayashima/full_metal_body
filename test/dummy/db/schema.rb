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

ActiveRecord::Schema[7.0].define(version: 2022_02_15_102650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blocked_actions", force: :cascade do |t|
    t.string "controller", null: false
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller", "action"], name: "index_blocked_actions_on_controller_and_action", unique: true
  end

  create_table "blocked_keys", force: :cascade do |t|
    t.bigint "blocked_action_id", null: false
    t.string "blocked_key", null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_action_id", "blocked_key"], name: "index_blocked_keys_on_blocked_action_id_and_blocked_key", unique: true
    t.index ["blocked_action_id"], name: "index_blocked_keys_on_blocked_action_id"
  end

  add_foreign_key "blocked_keys", "blocked_actions"
end
