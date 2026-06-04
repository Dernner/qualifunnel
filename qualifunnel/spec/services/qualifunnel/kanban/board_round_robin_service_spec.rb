# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::Kanban::BoardRoundRobinService do
  let(:account) { create(:account) }
  let(:board) { create(:kanban_board, account: account) }
  let(:agent1) { create(:user, account: account) }
  let(:agent2) { create(:user, account: account) }
  let(:service) { described_class.new(board: board) }
  let(:redis_key) { "KANBAN_BOARD_ROUND_ROBIN_AGENTS:#{board.id}" }

  before do
    create(:kanban_board_agent, board: board, agent: agent1)
    create(:kanban_board_agent, board: board, agent: agent2)
  end

  describe '#clear_queue' do
    it 'removes the round robin key from Redis' do
      expect(Redis::Alfred).to receive(:delete).with(redis_key)
      service.clear_queue
    end
  end

  describe '#add_agent_to_queue' do
    it 'pushes the agent id to the head of the Redis list' do
      expect(Redis::Alfred).to receive(:lpush).with(redis_key, agent1.id)
      service.add_agent_to_queue(agent1.id)
    end
  end

  describe '#remove_agent_from_queue' do
    it 'removes the agent id from the Redis list' do
      expect(Redis::Alfred).to receive(:lrem).with(redis_key, agent1.id)
      service.remove_agent_from_queue(agent1.id)
    end
  end

  describe '#reset_queue' do
    it 'clears the key and repopulates with all board agent ids' do
      expect(Redis::Alfred).to receive(:delete).with(redis_key).ordered
      expect(Redis::Alfred).to receive(:lpush).with(redis_key, match_array([agent1.id, agent2.id])).ordered
      service.reset_queue
    end
  end

  describe '#available_agent' do
    context 'when the queue matches the current board agents' do
      before do
        allow(Redis::Alfred).to receive(:lrange).with(redis_key)
                                                .and_return([agent1.id.to_s, agent2.id.to_s])
        allow(Redis::Alfred).to receive(:lrem)
        allow(Redis::Alfred).to receive(:lpush)
      end

      it 'returns the agent whose id is in allowed_agent_ids' do
        result = service.available_agent(allowed_agent_ids: [agent1.id.to_s])
        expect(result).to eq(agent1)
      end

      it 'returns nil when allowed_agent_ids is empty' do
        result = service.available_agent(allowed_agent_ids: [])
        expect(result).to be_nil
      end

      it 'returns nil when no queue member intersects with allowed_agent_ids' do
        result = service.available_agent(allowed_agent_ids: ['9999999'])
        expect(result).to be_nil
      end

      it 'rotates the selected agent to the back of the queue (pop-push)' do
        expect(Redis::Alfred).to receive(:lrem).with(redis_key, agent1.id.to_s).ordered
        expect(Redis::Alfred).to receive(:lpush).with(redis_key, agent1.id.to_s).ordered
        service.available_agent(allowed_agent_ids: [agent1.id.to_s])
      end
    end

    context 'when the queue is stale (does not match board agents)' do
      before do
        allow(Redis::Alfred).to receive(:lrange).with(redis_key).and_return([])
        allow(Redis::Alfred).to receive(:delete)
        allow(Redis::Alfred).to receive(:lpush)
        allow(Redis::Alfred).to receive(:lrem)
      end

      it 'resets the queue before selecting an agent' do
        expect(Redis::Alfred).to receive(:delete).with(redis_key)
        service.available_agent(allowed_agent_ids: [agent1.id.to_s])
      end
    end
  end
end
