# frozen_string_literal: true

class CreateKanbanJoinTables < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_task_agents do |t|
      t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.timestamps
      t.index [:task_id, :agent_id], unique: true
    end

    create_table :kanban_task_contacts do |t|
      t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
      t.references :contact, null: false, foreign_key: true
      t.timestamps
      t.index [:task_id, :contact_id], unique: true
    end

    create_table :kanban_board_agents do |t|
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.timestamps
      t.index [:board_id, :agent_id], unique: true
    end

    create_table :kanban_board_inboxes do |t|
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
      t.references :inbox, null: false, foreign_key: true
      t.timestamps
      t.index [:board_id, :inbox_id], unique: true
    end

    create_table :kanban_products do |t|
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }
      t.string :name, null: false
      t.decimal :unit_price, precision: 15, scale: 2, default: 0
      t.text :description
      t.boolean :archived, default: false
      t.timestamps
    end

    create_table :kanban_task_products do |t|
      t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
      t.references :product, null: false, foreign_key: { to_table: :kanban_products }
      t.integer :quantity, default: 1
      t.decimal :unit_price, precision: 15, scale: 2, default: 0
      t.decimal :discount_percentage, precision: 5, scale: 2, default: 0
      t.timestamps
    end

    create_table :kanban_audit_events do |t|
      t.references :account, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: { to_table: :kanban_tasks }
      t.bigint :performed_by_id
      t.string :action, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
      t.foreign_key :users, column: :performed_by_id
    end

    create_table :kanban_account_user_preferences do |t|
      t.references :account_user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :preferences, default: {}
      t.timestamps
    end
  end
end
