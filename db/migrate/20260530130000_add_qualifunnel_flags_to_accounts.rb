# frozen_string_literal: true

class AddQualifunnelFlagsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :qualifunnel_flags, :bigint, default: 0, null: false
  end
end
