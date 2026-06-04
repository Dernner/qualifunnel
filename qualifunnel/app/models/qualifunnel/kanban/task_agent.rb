# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TaskAgent < ApplicationRecord
      self.table_name = 'kanban_task_agents'

      belongs_to :task,
                 class_name: 'Qualifunnel::Kanban::Task',
                 foreign_key: :task_id,
                 inverse_of: :task_agents

      belongs_to :agent,
                 class_name: 'User',
                 foreign_key: :agent_id

      validates :task_id, uniqueness: { scope: :agent_id }
    end
  end
end
