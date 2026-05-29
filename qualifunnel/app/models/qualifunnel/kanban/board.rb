# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_boards
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :text
#  settings    :jsonb            not null, default: {}
#  account_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Qualifunnel
  module Kanban
    class Board < ApplicationRecord
      self.table_name = 'kanban_boards'

      belongs_to :account

      has_many :steps,
               -> { order(:position) },
               class_name: 'Qualifunnel::Kanban::BoardStep',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      has_many :tasks,
               class_name: 'Qualifunnel::Kanban::Task',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      validates :name, presence: true
      validates :name, uniqueness: { scope: :account_id, case_sensitive: false }

      store_accessor :settings, :default_view

      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :recent, -> { order(updated_at: :desc) }
    end
  end
end
