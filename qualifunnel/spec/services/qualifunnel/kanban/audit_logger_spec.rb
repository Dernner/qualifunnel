# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::Kanban::AuditLogger do
  let(:account) { create(:account) }
  let(:board) { create(:kanban_board, account: account) }
  let(:step) { create(:kanban_board_step, board: board) }
  let(:task) { create(:kanban_task, account: account, board: board, board_step: step) }

  before { allow(account).to receive(:kanban_feature_enabled?).and_return(true) }

  describe '#call' do
    subject(:logger) { described_class.new(task: task, action: 'task_created') }

    context 'when kanban feature is enabled' do
      it 'creates an audit event' do
        expect { logger.call }.to change(Qualifunnel::Kanban::AuditEvent, :count).by(1)
      end

      it 'records the action' do
        logger.call
        expect(Qualifunnel::Kanban::AuditEvent.last.action).to eq('task_created')
      end

      it 'associates the event with the correct task and account' do
        logger.call
        event = Qualifunnel::Kanban::AuditEvent.last
        expect(event.task).to eq(task)
        expect(event.account).to eq(account)
      end
    end

    context 'when metadata is provided' do
      subject(:logger) do
        described_class.new(task: task, action: 'task_updated', metadata: { 'field' => 'priority', 'to' => 'high' })
      end

      it 'stores the metadata on the audit event' do
        logger.call
        expect(Qualifunnel::Kanban::AuditEvent.last.metadata).to eq('field' => 'priority', 'to' => 'high')
      end
    end

    context 'when metadata is nil' do
      subject(:logger) { described_class.new(task: task, action: 'task_created', metadata: nil) }

      it 'defaults metadata to an empty hash' do
        logger.call
        expect(Qualifunnel::Kanban::AuditEvent.last.metadata).to eq({})
      end
    end

    context 'when performed_by is provided' do
      let(:user) { create(:user, account: account) }

      subject(:logger) { described_class.new(task: task, action: 'task_created', performed_by: user) }

      it 'records the performer on the audit event' do
        logger.call
        expect(Qualifunnel::Kanban::AuditEvent.last.performed_by).to eq(user)
      end
    end

    context 'when occurred_at is provided' do
      let(:custom_time) { 2.days.ago.change(usec: 0) }

      subject(:logger) { described_class.new(task: task, action: 'task_created', occurred_at: custom_time) }

      it 'overrides the created_at timestamp of the audit event' do
        logger.call
        expect(Qualifunnel::Kanban::AuditEvent.last.created_at).to be_within(1.second).of(custom_time)
      end
    end

    context 'when kanban feature is disabled' do
      before { allow(account).to receive(:kanban_feature_enabled?).and_return(false) }

      it 'does not create an audit event' do
        expect { logger.call }.not_to change(Qualifunnel::Kanban::AuditEvent, :count)
      end

      it 'returns nil' do
        expect(logger.call).to be_nil
      end
    end
  end

  describe '.log' do
    it 'delegates to a new instance and calls #call' do
      expect { described_class.log(task: task, action: 'task_created') }
        .to change(Qualifunnel::Kanban::AuditEvent, :count).by(1)
    end
  end
end
