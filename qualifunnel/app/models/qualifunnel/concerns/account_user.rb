# frozen_string_literal: true

module Qualifunnel::Concerns::AccountUser
  extend ActiveSupport::Concern

  included do
    has_many :kanban_task_agents,
             class_name: 'Qualifunnel::Kanban::TaskAgent',
             foreign_key: :agent_id,
             dependent: :destroy,
             inverse_of: :agent

    has_many :kanban_assigned_tasks,
             through: :kanban_task_agents,
             class_name: 'Qualifunnel::Kanban::Task',
             source: :task

    has_many :kanban_created_tasks,
             class_name: 'Qualifunnel::Kanban::Task',
             foreign_key: :created_by_id,
             dependent: :nullify,
             inverse_of: :created_by

    has_many :kanban_board_agents,
             class_name: 'Qualifunnel::Kanban::BoardAgent',
             foreign_key: :agent_id,
             dependent: :destroy,
             inverse_of: :agent

    has_many :kanban_boards,
             through: :kanban_board_agents,
             class_name: 'Qualifunnel::Kanban::Board',
             source: :board

    has_many :kanban_audit_events,
             class_name: 'Qualifunnel::Kanban::AuditEvent',
             foreign_key: :performed_by_id,
             dependent: :nullify,
             inverse_of: :performed_by

    has_one :kanban_preference,
            class_name: 'Qualifunnel::Kanban::AccountUserPreference',
            foreign_key: :account_user_id,
            dependent: :destroy,
            inverse_of: :account_user
  end
end
