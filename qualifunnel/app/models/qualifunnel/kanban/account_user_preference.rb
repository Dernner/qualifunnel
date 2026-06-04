# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class AccountUserPreference < ApplicationRecord
      self.table_name = 'kanban_account_user_preferences'

      belongs_to :account_user,
                 class_name: 'AccountUser',
                 foreign_key: :account_user_id,
                 inverse_of: :kanban_preference

      validates :account_user_id, uniqueness: true

      store_accessor :preferences,
                     :board_sorting,
                     :favorite_board_ids,
                     :tasks_order,
                     :task_sorting
    end
  end
end
