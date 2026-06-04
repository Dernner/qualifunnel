# frozen_string_literal: true

class AddColumnsToKanbanTables < ActiveRecord::Migration[7.1]
  def change
    # kanban_tasks
    add_column :kanban_tasks, :priority, :integer, default: 0
    add_column :kanban_tasks, :start_date, :datetime
    add_column :kanban_tasks, :value, :decimal, precision: 15, scale: 2
    add_column :kanban_tasks, :created_by_id, :bigint
    add_column :kanban_tasks, :custom_attributes, :jsonb, default: {}
    add_column :kanban_tasks, :cached_label_list, :text
    add_column :kanban_tasks, :step_changed_at, :datetime
    add_foreign_key :kanban_tasks, :users, column: :created_by_id

    # kanban_board_steps
    add_column :kanban_board_steps, :probability, :decimal, precision: 5, scale: 2, default: 0
    add_column :kanban_board_steps, :color, :string
    add_column :kanban_board_steps, :description, :text
    add_column :kanban_board_steps, :tasks_count, :integer, default: 0, null: false

    # kanban_boards
    add_column :kanban_boards, :currency, :string, default: 'USD'
    add_column :kanban_boards, :steps_order, :integer, array: true, default: []
  end
end
