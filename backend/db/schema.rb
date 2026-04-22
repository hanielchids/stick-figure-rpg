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

ActiveRecord::Schema[8.1].define(version: 2026_04_22_102807) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "loadouts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crosshair_style"
    t.string "preferred_weapon"
    t.string "skin_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_loadouts_on_user_id"
  end

  create_table "match_participants", force: :cascade do |t|
    t.string "bot_name"
    t.datetime "created_at", null: false
    t.integer "damage_dealt"
    t.integer "damage_taken"
    t.integer "deaths"
    t.integer "kills"
    t.bigint "match_id", null: false
    t.integer "placement"
    t.integer "team"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "xp_earned"
    t.index ["match_id"], name: "index_match_participants_on_match_id"
    t.index ["user_id"], name: "index_match_participants_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_sec"
    t.datetime "ended_at"
    t.string "map"
    t.string "mode"
    t.datetime "started_at"
    t.string "state"
    t.datetime "updated_at", null: false
  end

  create_table "player_stats", force: :cascade do |t|
    t.integer "best_kill_streak"
    t.datetime "created_at", null: false
    t.integer "deaths"
    t.integer "kills"
    t.integer "losses"
    t.integer "matches_played"
    t.integer "time_played_sec"
    t.integer "total_xp"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "wins"
    t.index ["user_id"], name: "index_player_stats_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "elo_rating"
    t.string "email"
    t.datetime "last_login_at"
    t.integer "level"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.string "username"
    t.integer "xp_current"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "loadouts", "users"
  add_foreign_key "match_participants", "matches"
  add_foreign_key "match_participants", "users"
  add_foreign_key "player_stats", "users"
end
