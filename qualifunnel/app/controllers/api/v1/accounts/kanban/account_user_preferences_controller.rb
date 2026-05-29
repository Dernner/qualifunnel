# frozen_string_literal: true

class Api::V1::Accounts::Kanban::AccountUserPreferencesController < Api::V1::Accounts::Kanban::BaseController
  def update
    current_user.update!(
      custom_attributes: current_user.custom_attributes.merge(
        'kanban_preferences' => preferences_params.to_h
      )
    )
    render json: { preferences: preferences_params }
  end

  private

  def preferences_params
    params.require(:preferences).permit(:default_board_id, :sidebar_collapsed, :card_view)
  end
end
