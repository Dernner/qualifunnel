# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board, only: [:show, :update, :destroy]

  def index
    @boards = Current.account.kanban_boards.recent
    render json: @boards
  end

  def show
    render json: @board
  end

  def create
    @board = Current.account.kanban_boards.build(board_params)
    if @board.save
      render json: @board, status: :created
    else
      render json: { errors: @board.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @board.update(board_params)
      render json: @board
    else
      render json: { errors: @board.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @board.destroy!
    head :no_content
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :description, settings: [:default_view])
  end
end
