# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::Kanban::TaskAutoAssignmentService do
  let(:account) { create(:account) }
  let(:board) do
    create(:kanban_board, account: account, settings: { 'auto_assign_task_to_agent' => true })
  end
  let(:step) { create(:kanban_board_step, board: board) }
  let(:task) { create(:kanban_task, account: account, board: board, board_step: step) }
  let(:agent) { create(:user, account: account) }
  let(:round_robin_service) { instance_double(Qualifunnel::Kanban::BoardRoundRobinService) }

  subject(:service) { described_class.new(task: task) }

  before do
    create(:kanban_board_agent, board: board, agent: agent)
    allow(Qualifunnel::Kanban::BoardRoundRobinService).to receive(:new)
      .with(board: board).and_return(round_robin_service)
  end

  describe '#perform' do
    context 'when the task already has assigned agents' do
      before { task.agents << agent }

      it 'skips assignment and returns early' do
        expect(round_robin_service).not_to receive(:available_agent)
        service.perform
      end
    end

    context 'when the board has auto_assign_task_to_agent disabled' do
      let(:board) do
        create(:kanban_board, account: account, settings: { 'auto_assign_task_to_agent' => false })
      end

      it 'skips assignment and returns early' do
        expect(round_robin_service).not_to receive(:available_agent)
        service.perform
        expect(task.reload.agents).to be_empty
      end
    end

    context 'when auto_assign is enabled and the task has no agents' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                                   .and_return({ agent.id.to_s => 'online' })
        allow(round_robin_service).to receive(:available_agent)
          .with(allowed_agent_ids: [agent.id.to_s]).and_return(agent)
      end

      it 'assigns the available online agent to the task' do
        service.perform
        expect(task.reload.agents).to include(agent)
      end

      it 'dispatches a KANBAN_TASK_UPDATED event' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Qualifunnel::Events::Types::KANBAN_TASK_UPDATED,
          anything,
          hash_including(task: task)
        )
        service.perform
      end

      it 'includes the new agent ids in the changed_attributes payload' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          anything,
          anything,
          hash_including(changed_attributes: { 'agent_ids' => [[], [agent.id]] })
        )
        service.perform
      end
    end

    context 'when no online agents are available' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                                   .and_return({ agent.id.to_s => 'busy' })
        allow(round_robin_service).to receive(:available_agent)
          .with(allowed_agent_ids: []).and_return(nil)
      end

      it 'does not assign any agent' do
        service.perform
        expect(task.reload.agents).to be_empty
      end

      it 'does not dispatch an event' do
        expect(Rails.configuration.dispatcher).not_to receive(:dispatch)
        service.perform
      end
    end

    context 'when the round robin service returns nil' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                                   .and_return({ agent.id.to_s => 'online' })
        allow(round_robin_service).to receive(:available_agent)
          .with(allowed_agent_ids: [agent.id.to_s]).and_return(nil)
      end

      it 'does not assign any agent' do
        service.perform
        expect(task.reload.agents).to be_empty
      end
    end
  end

  describe '#find_assignee' do
    before do
      allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                                 .and_return({ agent.id.to_s => 'online' })
      allow(round_robin_service).to receive(:available_agent)
        .with(allowed_agent_ids: [agent.id.to_s]).and_return(agent)
    end

    it 'returns the next available online board agent' do
      expect(service.find_assignee).to eq(agent)
    end

    context 'when the agent is online but not a board member' do
      let(:non_board_agent) { create(:user, account: account) }

      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id)
                                                                   .and_return({ non_board_agent.id.to_s => 'online' })
        allow(round_robin_service).to receive(:available_agent)
          .with(allowed_agent_ids: []).and_return(nil)
      end

      it 'returns nil' do
        expect(service.find_assignee).to be_nil
      end
    end
  end
end
