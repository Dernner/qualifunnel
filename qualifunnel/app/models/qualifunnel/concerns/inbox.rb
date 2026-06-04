# frozen_string_literal: true

module Qualifunnel::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_many :kanban_board_inboxes,
             class_name: 'Qualifunnel::Kanban::BoardInbox',
             foreign_key: :inbox_id,
             dependent: :destroy,
             inverse_of: :inbox

    has_many :kanban_boards,
             through: :kanban_board_inboxes,
             class_name: 'Qualifunnel::Kanban::Board',
             source: :board
  end
end
