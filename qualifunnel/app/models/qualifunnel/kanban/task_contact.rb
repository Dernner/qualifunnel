# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TaskContact < ApplicationRecord
      self.table_name = 'kanban_task_contacts'

      belongs_to :task,
                 class_name: 'Qualifunnel::Kanban::Task',
                 foreign_key: :task_id,
                 inverse_of: :task_contacts

      belongs_to :contact,
                 class_name: 'Contact',
                 foreign_key: :contact_id

      validates :task_id, uniqueness: { scope: :contact_id }
    end
  end
end
