# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardInboxesController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board

  def index
    authorize Qualifunnel::Kanban::BoardInbox
    @inboxes = @board.inboxes
    render json: @inboxes
  end

  def create
    authorize Qualifunnel::Kanban::BoardInbox
    inbox = Current.account.inboxes.find(params[:inbox_id])
    @board_inbox = @board.board_inboxes.find_or_create_by!(inbox: inbox)
    render json: { id: @board_inbox.id, inbox_id: inbox.id }, status: :created
  end

  def destroy
    authorize Qualifunnel::Kanban::BoardInbox
    board_inbox = @board.board_inboxes.find_by!(inbox_id: params[:id])
    board_inbox.destroy!
    head :no_content
  end

  def update_inboxes
    authorize Qualifunnel::Kanban::BoardInbox, :update_inboxes?
    inbox_ids = params[:inbox_ids].to_a.map(&:to_i)
    inboxes = Current.account.inboxes.where(id: inbox_ids)

    @board.board_inboxes.where.not(inbox_id: inbox_ids).destroy_all
    inboxes.each { |inbox| @board.board_inboxes.find_or_create_by!(inbox: inbox) }

    render json: { inbox_ids: @board.board_inboxes.pluck(:inbox_id) }
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end
end
