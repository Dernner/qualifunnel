# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class BoardInbox < ApplicationRecord
      self.table_name = 'kanban_board_inboxes'

      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :board_inboxes

      belongs_to :inbox,
                 class_name: 'Inbox',
                 foreign_key: :inbox_id

      validates :board_id, uniqueness: { scope: :inbox_id }
    end
  end
end
