# frozen_string_literal: true

class Api::V1::Accounts::Kanban::BoardAgentsController < Api::V1::Accounts::Kanban::BaseController
  before_action :find_board

  def index
    authorize Qualifunnel::Kanban::BoardAgent
    @agents = @board.agents
    render json: @agents
  end

  def create
    authorize Qualifunnel::Kanban::BoardAgent
    agent = Current.account.users.find(params[:agent_id])
    @board_agent = @board.board_agents.find_or_create_by!(agent: agent)
    render json: { id: @board_agent.id, agent_id: agent.id }, status: :created
  end

  def destroy
    authorize Qualifunnel::Kanban::BoardAgent
    board_agent = @board.board_agents.find_by!(agent_id: params[:id])
    board_agent.destroy!
    head :no_content
  end

  def update_agents
    authorize Qualifunnel::Kanban::BoardAgent, :update_agents?
    agent_ids = params[:agent_ids].to_a.map(&:to_i)
    agents = Current.account.users.where(id: agent_ids)

    @board.board_agents.where.not(agent_id: agent_ids).destroy_all
    agents.each { |agent| @board.board_agents.find_or_create_by!(agent: agent) }

    render json: { agent_ids: @board.board_agents.pluck(:agent_id) }
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find(params[:board_id])
  end
end
