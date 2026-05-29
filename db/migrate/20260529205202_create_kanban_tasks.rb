# frozen_string_literal: true

class CreateKanbanTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_tasks do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }, index: true
      t.references :board_step, null: false, foreign_key: { to_table: :kanban_board_steps }, index: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.datetime :due_date

      t.timestamps
    end

    add_index :kanban_tasks, [:board_step_id, :position]
    add_index :kanban_tasks, :due_date
  end
end
