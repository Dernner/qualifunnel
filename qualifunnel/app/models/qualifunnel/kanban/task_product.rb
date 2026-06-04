# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TaskProduct < ApplicationRecord
      self.table_name = 'kanban_task_products'

      belongs_to :task,
                 class_name: 'Qualifunnel::Kanban::Task',
                 foreign_key: :task_id,
                 inverse_of: :task_products

      belongs_to :product,
                 class_name: 'Qualifunnel::Kanban::Product',
                 foreign_key: :product_id,
                 inverse_of: :task_products

      validates :quantity, numericality: { only_integer: true, greater_than: 0 }
      validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
      validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

      def total_price
        unit_price * quantity * (1 - discount_percentage / 100.0)
      end
    end
  end
end
