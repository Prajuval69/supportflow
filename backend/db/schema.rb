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

ActiveRecord::Schema[7.2].define(version: 2026_11_01_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "audit_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "actor_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["organization_id"], name: "index_audit_events_on_organization_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "organization_id, lower((name)::text)", name: "index_categories_on_organization_id_lower_name", unique: true
    t.index ["organization_id", "id"], name: "index_categories_on_organization_id_and_id", unique: true
    t.index ["organization_id"], name: "index_categories_on_organization_id"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "ticket_id", null: false
    t.uuid "author_id", null: false
    t.text "body", null: false
    t.string "visibility", default: "public", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["organization_id"], name: "index_comments_on_organization_id"
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
    t.check_constraint "visibility::text = ANY (ARRAY['public'::character varying, 'internal'::character varying]::text[])", name: "comment_visibility"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.string "role", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'agent'::character varying, 'customer'::character varying]::text[])", name: "membership_role"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.uuid "ticket_id"
    t.string "kind", null: false
    t.string "message", null: false
    t.string "dedupe_key", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id", "dedupe_key"], name: "unique_notification_delivery", unique: true
    t.index ["organization_id", "user_id", "read_at"], name: "index_notifications_on_organization_id_and_user_id_and_read_at"
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["ticket_id"], name: "index_notifications_on_ticket_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "ticket_sequence", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "sla_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "priority", null: false
    t.integer "first_response_minutes", null: false
    t.integer "resolution_minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "priority"], name: "index_sla_policies_on_organization_id_and_priority", unique: true
    t.index ["organization_id"], name: "index_sla_policies_on_organization_id"
    t.check_constraint "first_response_minutes > 0 AND resolution_minutes > 0 AND first_response_minutes <= 525600 AND resolution_minutes <= 525600", name: "positive_sla"
  end

  create_table "ticket_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "ticket_id", null: false
    t.uuid "actor_id"
    t.string "event_type", null: false
    t.string "dedupe_key"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_ticket_events_on_actor_id"
    t.index ["organization_id", "ticket_id", "created_at"], name: "idx_on_organization_id_ticket_id_created_at_f226cd423f"
    t.index ["organization_id", "ticket_id", "dedupe_key"], name: "idx_on_organization_id_ticket_id_dedupe_key_eb60298d00", unique: true
    t.index ["organization_id"], name: "index_ticket_events_on_organization_id"
    t.index ["ticket_id"], name: "index_ticket_events_on_ticket_id"
  end

  create_table "tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "ticket_number", null: false
    t.uuid "created_by_id", null: false
    t.uuid "assignee_id"
    t.uuid "category_id"
    t.string "title", limit: 200, null: false
    t.text "description", null: false
    t.string "priority", null: false
    t.string "status", default: "open", null: false
    t.datetime "first_response_at"
    t.datetime "first_response_due_at", null: false
    t.datetime "resolution_due_at", null: false
    t.datetime "resolved_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["category_id"], name: "index_tickets_on_category_id"
    t.index ["created_by_id"], name: "index_tickets_on_created_by_id"
    t.index ["first_response_due_at"], name: "index_tickets_on_first_response_due_at", where: "(first_response_at IS NULL)"
    t.index ["organization_id", "assignee_id", "status"], name: "index_tickets_on_organization_id_and_assignee_id_and_status"
    t.index ["organization_id", "created_by_id", "created_at"], name: "idx_on_organization_id_created_by_id_created_at_fbc7e1509f"
    t.index ["organization_id", "id"], name: "index_tickets_on_organization_id_and_id", unique: true
    t.index ["organization_id", "priority", "resolution_due_at"], name: "idx_on_organization_id_priority_resolution_due_at_9388e32897"
    t.index ["organization_id", "status", "created_at"], name: "index_tickets_on_organization_id_and_status_and_created_at"
    t.index ["organization_id", "ticket_number"], name: "index_tickets_on_organization_id_and_ticket_number", unique: true
    t.index ["organization_id"], name: "index_tickets_on_organization_id"
    t.index ["resolution_due_at"], name: "index_tickets_on_resolution_due_at"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying, 'normal'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])", name: "ticket_priority"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'in_progress'::character varying, 'waiting_on_customer'::character varying, 'resolved'::character varying, 'closed'::character varying]::text[])", name: "ticket_status"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "audit_events", "organizations"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "categories", "organizations"
  add_foreign_key "comments", "organizations"
  add_foreign_key "comments", "tickets"
  add_foreign_key "comments", "tickets", column: ["organization_id", "ticket_id"], primary_key: ["organization_id", "id"]
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "organizations"
  add_foreign_key "notifications", "tickets"
  add_foreign_key "notifications", "tickets", column: ["organization_id", "ticket_id"], primary_key: ["organization_id", "id"]
  add_foreign_key "notifications", "users"
  add_foreign_key "sla_policies", "organizations"
  add_foreign_key "ticket_events", "organizations"
  add_foreign_key "ticket_events", "tickets"
  add_foreign_key "ticket_events", "tickets", column: ["organization_id", "ticket_id"], primary_key: ["organization_id", "id"]
  add_foreign_key "ticket_events", "users", column: "actor_id"
  add_foreign_key "tickets", "categories"
  add_foreign_key "tickets", "categories", column: ["organization_id", "category_id"], primary_key: ["organization_id", "id"]
  add_foreign_key "tickets", "organizations"
  add_foreign_key "tickets", "users", column: "assignee_id"
  add_foreign_key "tickets", "users", column: "created_by_id"
end
