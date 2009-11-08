# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 10) do

  create_table "requests", :force => true do |t|
    t.string   "environment"
    t.string   "controller"
    t.string   "action"
    t.string   "ip"
    t.datetime "time"
    t.string   "http_method"
    t.text     "parameters"
    t.integer  "view_time"
    t.integer  "db_time"
    t.string   "http_response"
    t.text     "url"
    t.string   "embed_key"
    t.string   "permalink"
    t.string   "error"
  end

end
