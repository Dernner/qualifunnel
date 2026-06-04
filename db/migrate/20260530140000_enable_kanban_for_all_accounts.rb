# frozen_string_literal: true

class EnableKanbanForAllAccounts < ActiveRecord::Migration[7.1]
  def up
    change_column_default :accounts, :qualifunnel_flags, from: 0, to: 1
    execute 'UPDATE accounts SET qualifunnel_flags = qualifunnel_flags | 1'
  end

  def down
    change_column_default :accounts, :qualifunnel_flags, from: 1, to: 0
    execute 'UPDATE accounts SET qualifunnel_flags = qualifunnel_flags & ~1'
  end
end
