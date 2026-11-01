class CreateSupportflow < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto'
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, 'lower(email)', unique: true
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.bigint :ticket_sequence, null: false, default: 0
      t.timestamps
    end
    add_index :organizations, :slug, unique: true
    create_table :memberships, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :role, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :memberships, [:organization_id, :user_id], unique: true
    add_check_constraint :memberships, "role IN ('admin','agent','customer')", name: 'membership_role'
    create_table :categories, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :categories, 'organization_id, lower(name)', unique: true
    create_table :sla_policies, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.string :priority, null: false
      t.integer :first_response_minutes, null: false
      t.integer :resolution_minutes, null: false
      t.timestamps
    end
    add_index :sla_policies, [:organization_id, :priority], unique: true
    add_check_constraint :sla_policies, 'first_response_minutes > 0 AND resolution_minutes > 0 AND first_response_minutes <= 525600 AND resolution_minutes <= 525600', name: 'positive_sla'
    create_table :tickets, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.string :ticket_number, null: false
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :assignee, type: :uuid, foreign_key: { to_table: :users }
      t.references :category, type: :uuid, foreign_key: true
      t.string :title, null: false, limit: 200
      t.text :description, null: false
      t.string :priority, null: false
      t.string :status, null: false, default: 'open'
      t.datetime :first_response_at
      t.datetime :first_response_due_at, null: false
      t.datetime :resolution_due_at, null: false
      t.datetime :resolved_at
      t.datetime :closed_at
      t.timestamps
    end
    add_index :tickets, [:organization_id, :ticket_number], unique: true
    add_index :tickets, [:organization_id, :status, :created_at]
    add_index :tickets, [:organization_id, :assignee_id, :status]
    add_index :tickets, [:organization_id, :priority, :resolution_due_at]
    add_index :tickets, [:organization_id, :created_by_id, :created_at]
    add_index :tickets, :first_response_due_at, where: 'first_response_at IS NULL'
    add_index :tickets, :resolution_due_at
    add_check_constraint :tickets, "priority IN ('low','normal','high','urgent')", name: 'ticket_priority'
    add_check_constraint :tickets, "status IN ('open','in_progress','waiting_on_customer','resolved','closed')", name: 'ticket_status'
    create_table :comments, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :ticket, type: :uuid, null: false, foreign_key: true
      t.references :author, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.string :visibility, null: false, default: 'public'
      t.timestamps
    end
    add_check_constraint :comments, "visibility IN ('public','internal')", name: 'comment_visibility'
    create_table :ticket_events, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :ticket, type: :uuid, null: false, foreign_key: true
      t.references :actor, type: :uuid, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.string :dedupe_key
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :ticket_events, [:organization_id, :ticket_id, :created_at]
    add_index :ticket_events, [:organization_id, :ticket_id, :dedupe_key], unique: true
    create_table :notifications, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :ticket, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.string :message, null: false
      t.string :dedupe_key, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, [:organization_id, :user_id, :dedupe_key], unique: true, name: 'unique_notification_delivery'
    add_index :notifications, [:organization_id, :user_id, :read_at]
    create_table :audit_events, id: :uuid do |t|
      t.references :organization, type: :uuid, null: false, foreign_key: true
      t.references :actor, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    # Composite foreign keys stop cross-tenant associations even below the service layer.
    [:categories, :tickets].each { |table| add_index table, [:organization_id, :id], unique: true }
    add_foreign_key :tickets, :categories, column: [:organization_id, :category_id], primary_key: [:organization_id, :id]
    [:comments, :ticket_events, :notifications].each do |table|
      add_foreign_key table, :tickets, column: [:organization_id, :ticket_id], primary_key: [:organization_id, :id]
    end
  end
end
