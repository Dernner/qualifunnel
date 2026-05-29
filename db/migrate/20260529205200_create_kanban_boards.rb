# frozen_string_literal: true

class CreateKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_boards do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :kanban_boards, [:account_id, :name], unique: true
  end
end
