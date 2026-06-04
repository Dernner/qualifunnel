# frozen_string_literal: true

class Api::V1::Accounts::Kanban::AuditEventsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_task
  before_action :find_event, only: [:show]

  def index
    authorize Qualifunnel::Kanban::AuditEvent
    @events = @task.audit_events.recent.includes(:performed_by).page(params[:page]).per(50)
    render json: @events
  end

  def show
    authorize @event, policy_class: Qualifunnel::Kanban::AuditEventPolicy
    render json: @event
  end

  private

  def find_task
    @task = Current.account.kanban_tasks.find(params[:task_id])
  end

  def find_event
    @event = @task.audit_events.find(params[:id])
  end
end
