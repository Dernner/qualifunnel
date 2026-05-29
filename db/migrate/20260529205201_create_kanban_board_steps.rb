# frozen_string_literal: true

class CreateKanbanBoardSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_board_steps do |t|
      t.references :board, null: false, foreign_key: { to_table: :kanban_boards }, index: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :completed, null: false, default: false
      t.boolean :cancelled, null: false, default: false

      t.timestamps
    end

    add_index :kanban_board_steps, [:board_id, :position]
  end
end
