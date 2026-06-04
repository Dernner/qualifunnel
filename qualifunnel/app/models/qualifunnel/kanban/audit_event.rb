# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class AuditEvent < ApplicationRecord
      self.table_name = 'kanban_audit_events'

      belongs_to :account
      belongs_to :task,
                 class_name: 'Qualifunnel::Kanban::Task',
                 foreign_key: :task_id,
                 inverse_of: :audit_events

      belongs_to :performed_by,
                 class_name: 'User',
                 foreign_key: :performed_by_id,
                 optional: true

      validates :action, presence: true

      scope :for_task, ->(task_id) { where(task_id: task_id) }
      scope :recent, -> { order(created_at: :desc) }
    end
  end
end
