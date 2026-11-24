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

ActiveRecord::Schema[8.0].define(version: 2026_11_24_155754) do
  create_table "games", force: :cascade do |t|
    t.string "player_1_token", null: false
    t.string "player_2_token", null: false
    t.integer "status", default: 0, null: false
    t.integer "current_turn", default: 1, null: false
    t.integer "winner"
    t.json "board_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "capture_chain"
    t.index ["player_1_token"], name: "index_games_on_player_1_token", unique: true
    t.index ["player_2_token"], name: "index_games_on_player_2_token", unique: true
  end
end
