# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_tasks
#
#  id            :bigint           not null, primary key
#  account_id    :bigint           not null
#  board_id      :bigint           not null
#  board_step_id :bigint           not null
#  title         :string           not null
#  description   :text
#  position      :integer          not null, default: 0
#  due_date      :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
module Qualifunnel
  module Kanban
    class Task < ApplicationRecord
      self.table_name = 'kanban_tasks'

      belongs_to :account
      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :tasks

      belongs_to :board_step,
                 class_name: 'Qualifunnel::Kanban::BoardStep',
                 foreign_key: :board_step_id,
                 inverse_of: :tasks

      has_many :conversations,
               foreign_key: :kanban_task_id,
               dependent: :nullify,
               inverse_of: :kanban_task

      validates :title, presence: true
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :for_board, ->(board_id) { where(board_id: board_id) }
      scope :for_step, ->(step_id) { where(board_step_id: step_id) }
      scope :ordered, -> { order(:position) }
      scope :overdue, -> { where('due_date < ?', Time.current) }
      scope :due_soon, -> { where(due_date: Time.current..3.days.from_now) }
    end
  end
end
