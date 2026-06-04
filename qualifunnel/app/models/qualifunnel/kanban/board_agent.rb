# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class BoardAgent < ApplicationRecord
      self.table_name = 'kanban_board_agents'

      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :board_agents

      belongs_to :agent,
                 class_name: 'User',
                 foreign_key: :agent_id

      validates :board_id, uniqueness: { scope: :agent_id }
    end
  end
end
