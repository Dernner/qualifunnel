# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board, only: [:show, :update, :destroy, :update_agents, :update_inboxes, :toggle_favorite]

  def index
    authorize Qualifunnel::Kanban::Board
    boards = Current.account.kanban_boards.recent
    preferences = Current.account_user&.kanban_preference&.preferences || {}
    render json: {
      boards: boards.map { |b| serialize_board(b) },
      preferences: preferences
    }
  end

  def show
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    render json: serialize_board_with_steps(@board)
  end

  def create
    authorize Qualifunnel::Kanban::Board
    @board = Current.account.kanban_boards.build(board_params)
    if @board.save
      create_steps_from_template
      @board.reload
      render json: serialize_board_with_steps(@board), status: :created
    else
      render json: { errors: @board.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    if @board.update(board_params)
      render json: serialize_board_with_steps(@board)
    else
      render json: { errors: @board.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    @board.destroy!
    head :no_content
  end

  def update_agents
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    agent_ids = params[:agent_ids].to_a.map(&:to_i)
    agents = Current.account.users.where(id: agent_ids)
    @board.board_agents.where.not(agent_id: agent_ids).destroy_all
    agents.each { |agent| @board.board_agents.find_or_create_by!(agent: agent) }
    render json: { agent_ids: @board.board_agents.pluck(:agent_id) }
  end

  def update_inboxes
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    inbox_ids = params[:inbox_ids].to_a.map(&:to_i)
    inboxes = Current.account.inboxes.where(id: inbox_ids)
    @board.board_inboxes.where.not(inbox_id: inbox_ids).destroy_all
    inboxes.each { |inbox| @board.board_inboxes.find_or_create_by!(inbox: inbox) }
    render json: { inbox_ids: @board.board_inboxes.pluck(:inbox_id) }
  end

  def toggle_favorite
    authorize @board, policy_class: Qualifunnel::Kanban::BoardPolicy
    pref = Current.account_user.kanban_preference || Current.account_user.build_kanban_preference
    favorite_ids = pref.favorite_board_ids.to_a.map(&:to_i)
    new_ids = favorite_ids.include?(@board.id) ? favorite_ids - [@board.id] : favorite_ids + [@board.id]
    pref.update!(preferences: pref.preferences.merge('favorite_board_ids' => new_ids))
    render json: { favorited: new_ids.include?(@board.id), board_id: @board.id }
  end

  private

  def serialize_board(board)
    steps = board.ordered_steps.to_a
    tasks_with_value = board.tasks.where.not(value: nil).to_a
    steps_by_id = steps.index_by(&:id)

    total_value = tasks_with_value.sum { |t| t.value.to_f }
    total_weighted = tasks_with_value.sum do |t|
      prob = (steps_by_id[t.board_step_id]&.probability || 0).to_f / 100.0
      t.value.to_f * prob
    end

    {
      id: board.id,
      name: board.name,
      description: board.description,
      currency: board.currency,
      steps_order: board.steps_order,
      settings: board.settings,
      created_at: board.created_at,
      updated_at: board.updated_at,
      total_tasks_count: board.tasks.count,
      assigned_inbox_ids: board.board_inboxes.pluck(:inbox_id),
      total_value: total_value,
      total_weighted_value: total_weighted,
      assigned_agents: board.agents.map do |a|
        { id: a.id, name: a.name, avatar_url: a.avatar_url }
      end,
      steps_summary: steps.map do |s|
        { id: s.id, name: s.name, color: s.color, tasks_count: s.tasks.count,
          completed: s.completed, cancelled: s.cancelled }
      end
    }
  end

  def serialize_board_with_steps(board)
    base = serialize_board(board)
    base.merge(
      steps: board.steps.ordered.map do |s|
        { id: s.id, name: s.name, position: s.position, completed: s.completed,
          cancelled: s.cancelled, probability: s.probability, color: s.color,
          description: s.description, tasks_count: s.tasks_count }
      end,
      agent_ids: board.board_agents.pluck(:agent_id),
      inbox_ids: board.board_inboxes.pluck(:inbox_id)
    )
  end

  def find_board
    @board = Current.account.kanban_boards.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :description, :currency, steps_order: [], settings: [:default_view])
  end

  def create_steps_from_template
    steps_data = params.dig(:board, :steps_attributes)
    return if steps_data.blank?

    steps_data.each_with_index do |step_data, position|
      step = @board.steps.create!(
        name: step_data[:name],
        color: step_data[:color],
        description: step_data[:description],
        probability: step_data[:probability] || 0,
        completed: ActiveModel::Type::Boolean.new.cast(step_data[:completed]) || false,
        cancelled: ActiveModel::Type::Boolean.new.cast(step_data[:cancelled]) || false,
        position: position
      )

      next if step_data[:tasks_attributes].blank?

      step_data[:tasks_attributes].each_with_index do |task_data, task_position|
        @board.tasks.create!(
          account: Current.account,
          board_step: step,
          title: task_data[:title],
          description: task_data[:description],
          priority: task_data[:priority] || :low,
          value: task_data[:value],
          position: task_position
        )
      end
    end
  end
end
