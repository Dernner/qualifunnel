# frozen_string_literal: true

class Api::V1::Accounts::Kanban::AccountUserPreferencesController < Api::V1::Accounts::Kanban::BaseController
  def update
    authorize Qualifunnel::Kanban::AccountUserPreference, policy_class: Qualifunnel::Kanban::AccountUserPreferencePolicy
    preference = account_user.kanban_preference || account_user.build_kanban_preference
    preference.preferences = preference.preferences.merge(preferences_params.to_h)
    preference.save!
    render json: { preferences: preference.preferences }
  end

  private

  def account_user
    @account_user ||= Current.account_user
  end

  def preferences_params
    params.require(:preferences).permit(:board_sorting, :tasks_order, :task_sorting, favorite_board_ids: [])
  end
end
