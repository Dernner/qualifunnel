# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class Product < ApplicationRecord
      self.table_name = 'kanban_products'

      belongs_to :board,
                 class_name: 'Qualifunnel::Kanban::Board',
                 foreign_key: :board_id,
                 inverse_of: :products

      has_many :task_products,
               class_name: 'Qualifunnel::Kanban::TaskProduct',
               foreign_key: :product_id,
               dependent: :destroy,
               inverse_of: :product

      validates :name, presence: true
      validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

      scope :active, -> { where(archived: false) }
      scope :archived, -> { where(archived: true) }
    end
  end
end
