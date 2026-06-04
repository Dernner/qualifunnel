# frozen_string_literal: true

module Qualifunnel::Concerns::Account
  extend ActiveSupport::Concern

  QUALIFUNNEL_FEATURES = {
    1 => :feature_kanban
  }.freeze

  included do
    include FlagShihTzu

    has_flags QUALIFUNNEL_FEATURES.merge(
      column: 'qualifunnel_flags',
      flag_query_mode: :bit_operator,
      check_for_column: false
    )

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
    feature_kanban?
  end

  def all_features
    super.merge('kanban' => feature_kanban?)
  end
end

# Módulo separado para interceptar selected_feature_flags= e processar as flags do Qualifunnel
# antes de repassar o restante para Enterprise::Account ou Featurable.
module Qualifunnel::Concerns::AccountFlagInterceptor
  QUALIFUNNEL_FLAG_NAMES = Qualifunnel::Concerns::Account::QUALIFUNNEL_FEATURES.values.map(&:to_s).freeze

  def selected_feature_flags=(features)
    qualifunnel_flags = features.select { |f| QUALIFUNNEL_FLAG_NAMES.include?(f.to_s) }
    qualifunnel_flags.each { |f| send("#{f}=", true) }

    remaining = features.reject { |f| QUALIFUNNEL_FLAG_NAMES.include?(f.to_s) }
    super(remaining)
  end
end
