# frozen_string_literal: true

class Api::V1::Accounts::Kanban::TasksController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board, only: [:index, :create]
  before_action :find_task, only: [:update, :destroy, :move]

  def index
    @tasks = @board.tasks.ordered.includes(:board_step)
    render json: @tasks
  end

  def create
    step = @board.steps.find(task_params[:board_step_id])
    @task = Current.account.kanban_tasks.build(
      task_params.merge(board: @board, board_step: step)
    )
    @task.position = step.tasks.count

    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(update_task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  def move
    target_step = Current.account.kanban_boards
                         .joins(:steps)
                         .find_by('kanban_board_steps.id': params[:board_step_id])
                         &.steps&.find(params[:board_step_id])

    return head :unprocessable_entity unless target_step

    @task.update!(board_step: target_step, position: params[:position].to_i)
    render json: @task
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end

  def find_task
    @task = Current.account.kanban_tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :board_step_id, :position, :due_date)
  end

  def update_task_params
    params.require(:task).permit(:title, :description, :position, :due_date)
  end
end
