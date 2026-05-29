# frozen_string_literal: true

class AddKanbanTaskIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :kanban_task_id, :bigint
    add_index :conversations, :kanban_task_id
    add_foreign_key :conversations, :kanban_tasks, column: :kanban_task_id, on_delete: :nullify
  end
end
