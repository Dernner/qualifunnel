# frozen_string_literal: true

module Qualifunnel::Concerns::Conversation
  extend ActiveSupport::Concern

  included do
    belongs_to :kanban_task,
               class_name: 'Qualifunnel::Kanban::Task',
               foreign_key: :kanban_task_id,
               optional: true,
               inverse_of: :conversations
  end
end
