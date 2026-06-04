# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_tasks
#
#  id                 :bigint           not null, primary key
#  account_id         :bigint           not null
#  board_id           :bigint           not null
#  board_step_id      :bigint           not null
#  title              :string           not null
#  description        :text
#  position           :integer          not null, default: 0
#  due_date           :datetime
#  priority           :integer          default(0)
#  start_date         :datetime
#  value              :decimal(15,2)
#  created_by_id      :bigint
#  custom_attributes  :jsonb            default({})
#  cached_label_list  :text
#  step_changed_at    :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
module Qualifunnel
  module Kanban
    class Task < ApplicationRecord
      self.table_name = 'kanban_tasks'

      PRIORITIES = %w[urgent high medium low].freeze
      DESCRIPTION_MAX_LENGTH = 5000

      belongs_to :account
      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :tasks

      belongs_to :board_step,
                 class_name: 'Qualifunnel::Kanban::BoardStep',
                 foreign_key: :board_step_id,
                 inverse_of: :tasks

      belongs_to :created_by,
                 class_name: 'User',
                 foreign_key: :created_by_id,
                 optional: true

      has_many :conversations,
               foreign_key: :kanban_task_id,
               dependent: :nullify,
               inverse_of: :kanban_task

      has_many :task_agents,
               class_name: 'Qualifunnel::Kanban::TaskAgent',
               foreign_key: :task_id,
               dependent: :destroy,
               inverse_of: :task

      has_many :agents,
               through: :task_agents,
               class_name: 'User',
               source: :agent

      has_many :task_contacts,
               class_name: 'Qualifunnel::Kanban::TaskContact',
               foreign_key: :task_id,
               dependent: :destroy,
               inverse_of: :task

      has_many :contacts,
               through: :task_contacts,
               class_name: 'Contact',
               source: :contact

      has_many :task_products,
               class_name: 'Qualifunnel::Kanban::TaskProduct',
               foreign_key: :task_id,
               dependent: :destroy,
               inverse_of: :task

      has_many :products,
               through: :task_products,
               class_name: 'Qualifunnel::Kanban::Product',
               source: :product

      has_many :audit_events,
               class_name: 'Qualifunnel::Kanban::AuditEvent',
               foreign_key: :task_id,
               dependent: :destroy,
               inverse_of: :task

      enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }

      validates :title, presence: true
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :for_board, ->(board_id) { where(board_id: board_id) }
      scope :for_step, ->(step_id) { where(board_step_id: step_id) }
      scope :ordered, -> { order(:position) }
      scope :overdue, -> { where('due_date < ?', Time.current) }
      scope :due_soon, -> { where(due_date: Time.current..3.days.from_now) }
      scope :by_priority, -> { order(priority: :desc) }

      def label_list
        cached_label_list.to_s.split(',').map(&:strip).reject(&:blank?)
      end

      def add_labels(labels)
        new_list = (label_list + Array(labels)).uniq
        update!(cached_label_list: new_list.join(','))
      end

      def push_event_data
        {
          id: id,
          title: title,
          description: description,
          priority: priority,
          value: value,
          due_date: due_date,
          start_date: start_date,
          position: position,
          board_id: board_id,
          board_step_id: board_step_id,
          account_id: account_id,
          created_by_id: created_by_id,
          created_at: created_at,
          updated_at: updated_at
        }
      end
    end
  end
end
