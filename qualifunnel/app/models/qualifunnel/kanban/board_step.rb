# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_board_steps
#
#  id          :bigint           not null, primary key
#  board_id    :bigint           not null
#  name        :string           not null
#  position    :integer          not null, default: 0
#  completed   :boolean          not null, default: false
#  cancelled   :boolean          not null, default: false
#  probability :decimal(5,2)     default(0)
#  color       :string
#  description :text
#  tasks_count :integer          not null, default: 0
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Qualifunnel
  module Kanban
    class BoardStep < ApplicationRecord
      self.table_name = 'kanban_board_steps'

      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :steps

      has_many :tasks,
               class_name: 'Qualifunnel::Kanban::Task',
               foreign_key: :board_step_id,
               dependent: :nullify,
               inverse_of: :board_step

      validates :name, presence: true
      validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

      scope :ordered, -> { order(:position) }
      scope :completed, -> { where(completed: true) }
      scope :active, -> { where(completed: false, cancelled: false) }
    end
  end
end
