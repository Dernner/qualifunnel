# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardStepsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board
  before_action :find_step, only: [:show, :update, :destroy]

  def index
    @steps = @board.steps.ordered
    render json: @steps
  end

  def show
    render json: @step
  end

  def create
    @step = @board.steps.build(step_params)
    @step.position = @board.steps.count
    if @step.save
      render json: @step, status: :created
    else
      render json: { errors: @step.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @step.update(step_params)
      render json: @step
    else
      render json: { errors: @step.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @step.destroy!
    head :no_content
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end

  def find_step
    @step = @board.steps.find(params[:id])
  end

  def step_params
    params.require(:step).permit(:name, :position, :completed, :cancelled)
  end
end
