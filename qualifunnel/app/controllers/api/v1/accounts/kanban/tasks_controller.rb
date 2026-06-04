# frozen_string_literal: true

class Api::V1::Accounts::Kanban::TasksController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board, only: [:index, :create]
  before_action :find_task, only: [:show, :update, :destroy, :move]

  def index
    authorize Qualifunnel::Kanban::Task
    @tasks = @board.tasks.ordered.includes(:board_step, :agents, :contacts)
    render json: @tasks
  end

  def show
    authorize @task, policy_class: Qualifunnel::Kanban::TaskPolicy
    render json: @task
  end

  def create
    authorize Qualifunnel::Kanban::Task
    step = @board.steps.find(task_params[:board_step_id])
    @task = Current.account.kanban_tasks.build(
      task_params.merge(board: @board, board_step: step, created_by: current_user)
    )
    @task.position = step.tasks.count

    if @task.save
      dispatch_task_event(Qualifunnel::Events::Types::KANBAN_TASK_CREATED, @task)
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @task, policy_class: Qualifunnel::Kanban::TaskPolicy
    if @task.update(update_task_params)
      dispatch_task_event(Qualifunnel::Events::Types::KANBAN_TASK_UPDATED, @task)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task, policy_class: Qualifunnel::Kanban::TaskPolicy
    @task.destroy!
    head :no_content
  end

  def move
    authorize @task, policy_class: Qualifunnel::Kanban::TaskPolicy
    target_step = Current.account.kanban_boards
                         .joins(:steps)
                         .find_by('kanban_board_steps.id': params[:board_step_id])
                         &.steps&.find(params[:board_step_id])

    return head :unprocessable_entity unless target_step

    @task.update!(board_step: target_step, position: params[:position].to_i, step_changed_at: Time.current)

    event_type = if target_step.completed
                   Qualifunnel::Events::Types::KANBAN_TASK_WON
                 elsif target_step.cancelled
                   Qualifunnel::Events::Types::KANBAN_TASK_LOST
                 else
                   Qualifunnel::Events::Types::KANBAN_TASK_UPDATED
                 end
    dispatch_task_event(event_type, @task)

    render json: @task
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end

  def find_task
    @task = Current.account.kanban_tasks.find(params[:id])
  end

  def dispatch_task_event(event_name, task)
    Rails.configuration.dispatcher.dispatch(
      event_name, Time.zone.now, task: task, performed_by_id: current_user&.id
    )
  end

  def task_params
    params.require(:task).permit(
      :title, :description, :board_step_id, :position,
      :due_date, :start_date, :priority, :value, :cached_label_list,
      custom_attributes: {}
    )
  end

  def update_task_params
    params.require(:task).permit(
      :title, :description, :position,
      :due_date, :start_date, :priority, :value, :cached_label_list,
      custom_attributes: {}
    )
  end
end
