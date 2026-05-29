# frozen_string_literal: true

module Qualifunnel::Concerns::Account
  extend ActiveSupport::Concern

  included do
    has_many :kanban_boards,
             class_name: 'Qualifunnel::Kanban::Board',
             dependent: :destroy_async,
             inverse_of: :account
    has_many :kanban_tasks,
             class_name: 'Qualifunnel::Kanban::Task',
             dependent: :destroy_async,
             inverse_of: :account
  end

  def kanban_feature_enabled?
    # No Qualifunnel, o Kanban é livre — sem validação de assinatura
    feature_enabled?('kanban')
  end
end
