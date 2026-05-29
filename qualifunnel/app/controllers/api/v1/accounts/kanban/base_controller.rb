# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_kanban_feature_enabled

  private

  def ensure_kanban_feature_enabled
    return if Current.account&.kanban_feature_enabled?

    head :not_found
  end
end
