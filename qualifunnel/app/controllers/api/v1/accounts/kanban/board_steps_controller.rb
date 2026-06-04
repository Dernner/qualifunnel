# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardStepsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board
  before_action :find_step, only: [:show, :update, :destroy]

  def index
    authorize Qualifunnel::Kanban::BoardStep
    @steps = @board.steps.ordered
    render json: @steps
  end

  def show
    authorize @step, policy_class: Qualifunnel::Kanban::BoardStepPolicy
    render json: @step
  end

  def create
    authorize Qualifunnel::Kanban::BoardStep
    @step = @board.steps.build(step_params)
    @step.position = @board.steps.count
    if @step.save
      render json: @step, status: :created
    else
      render json: { errors: @step.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @step, policy_class: Qualifunnel::Kanban::BoardStepPolicy
    if @step.update(step_params)
      render json: @step
    else
      render json: { errors: @step.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @step, policy_class: Qualifunnel::Kanban::BoardStepPolicy
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
    params.require(:step).permit(:name, :position, :completed, :cancelled, :probability, :color, :description)
  end
end
