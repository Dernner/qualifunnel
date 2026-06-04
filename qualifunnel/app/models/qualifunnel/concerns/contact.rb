# frozen_string_literal: true

module Qualifunnel::Concerns::Contact
  extend ActiveSupport::Concern

  included do
    has_many :kanban_task_contacts,
             class_name: 'Qualifunnel::Kanban::TaskContact',
             foreign_key: :contact_id,
             dependent: :destroy,
             inverse_of: :contact

    has_many :kanban_tasks,
             through: :kanban_task_contacts,
             class_name: 'Qualifunnel::Kanban::Task',
             source: :task
  end
end
