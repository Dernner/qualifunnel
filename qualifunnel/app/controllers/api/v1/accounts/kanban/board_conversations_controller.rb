# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardConversationsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board

  def index
    @conversations = Current.account.conversations
                            .joins(:kanban_task)
                            .where(kanban_tasks: { board_id: @board.id })
                            .order(created_at: :desc)
                            .page(params[:page]).per(25)

    render json: {
      data: {
        meta: { count: @conversations.total_count, current_page: @conversations.current_page },
        payload: @conversations.map { |c| { id: c.id, display_id: c.display_id, kanban_task_id: c.kanban_task_id } }
      }
    }
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end
end
