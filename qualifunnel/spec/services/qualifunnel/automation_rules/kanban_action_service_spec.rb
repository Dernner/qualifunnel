# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::AutomationRules::KanbanActionService do
  let(:account) { create(:account) }
  let(:board) { create(:kanban_board, account: account) }
  let(:step) { create(:kanban_board_step, board: board, position: 0) }
  let(:task) { create(:kanban_task, account: account, board: board, board_step: step) }
  let(:rule) do
    instance_double(AutomationRule,
                    id: 1,
                    actions: actions,
                    event_name: 'kanban_task_created',
                    account_id: account.id)
  end
  let(:actions) { [] }

  subject(:service) { described_class.new(rule, account, task) }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    allow(ChatwootExceptionTracker).to receive_message_chain(:new, :capture_exception)
  end

  describe '#perform' do
    context 'assign_agent action' do
      let(:agent) { create(:user, account: account) }
      let(:actions) { [{ 'action_name' => 'assign_agent', 'action_params' => [agent.id] }] }

      before { create(:kanban_board_agent, board: board, agent: agent) }

      it 'assigns the agent to the task' do
        service.perform
        expect(task.reload.agents).to include(agent)
      end

      it 'does not duplicate assignment if agent is already assigned' do
        task.agents << agent
        expect { service.perform }.not_to change { task.agents.count }
      end

      context 'when the agent does not belong to the board' do
        before { board.board_agents.destroy_all }

        it 'does not assign the agent' do
          service.perform
          expect(task.reload.agents).not_to include(agent)
        end
      end

      context 'when agent_id is nil' do
        let(:actions) { [{ 'action_name' => 'assign_agent', 'action_params' => [] }] }

        it 'does nothing' do
          expect { service.perform }.not_to change { task.agents.count }
        end
      end
    end

    context 'assign_agent with "nil" (unassign)' do
      let(:agent) { create(:user, account: account) }
      let(:actions) { [{ 'action_name' => 'assign_agent', 'action_params' => ['nil'] }] }

      before do
        create(:kanban_board_agent, board: board, agent: agent)
        task.agents << agent
      end

      it 'removes all agents from the task' do
        service.perform
        expect(task.reload.agents).to be_empty
      end
    end

    context 'move_to_step action' do
      let(:target_step) { create(:kanban_board_step, board: board, position: 1) }
      let(:actions) { [{ 'action_name' => 'move_to_step', 'action_params' => [target_step.id] }] }

      it 'moves the task to the target step' do
        service.perform
        expect(task.reload.board_step).to eq(target_step)
      end

      context 'when step_ids is blank' do
        let(:actions) { [{ 'action_name' => 'move_to_step', 'action_params' => [] }] }

        it 'does not change the step' do
          service.perform
          expect(task.reload.board_step).to eq(step)
        end
      end

      context 'when the step does not belong to the board' do
        let(:other_board) { create(:kanban_board, account: account) }
        let(:other_step) { create(:kanban_board_step, board: other_board) }
        let(:actions) { [{ 'action_name' => 'move_to_step', 'action_params' => [other_step.id] }] }

        it 'does not change the step' do
          service.perform
          expect(task.reload.board_step).to eq(step)
        end
      end
    end

    context 'mark_completed action' do
      let(:completed_step) { create(:kanban_board_step, board: board, position: 2, completed: true) }
      let(:actions) { [{ 'action_name' => 'mark_completed', 'action_params' => nil }] }

      before { completed_step }

      it 'moves the task to the completed step' do
        service.perform
        expect(task.reload.board_step).to eq(completed_step)
      end

      context 'when no completed step exists on the board' do
        before { board.steps.where(completed: true).destroy_all }

        it 'does not change the step' do
          service.perform
          expect(task.reload.board_step).to eq(step)
        end
      end
    end

    context 'mark_cancelled action' do
      let(:cancelled_step) { create(:kanban_board_step, board: board, position: 3, cancelled: true) }
      let(:actions) { [{ 'action_name' => 'mark_cancelled', 'action_params' => nil }] }

      before { cancelled_step }

      it 'moves the task to the cancelled step' do
        service.perform
        expect(task.reload.board_step).to eq(cancelled_step)
      end

      context 'when no cancelled step exists on the board' do
        before { board.steps.where(cancelled: true).destroy_all }

        it 'does not change the step' do
          service.perform
          expect(task.reload.board_step).to eq(step)
        end
      end
    end

    context 'change_priority action' do
      let(:actions) { [{ 'action_name' => 'change_priority', 'action_params' => ['high'] }] }

      it 'updates the task priority' do
        service.perform
        expect(task.reload.priority).to eq('high')
      end

      context 'with an invalid priority value' do
        let(:actions) { [{ 'action_name' => 'change_priority', 'action_params' => ['critical'] }] }

        it 'does not change the priority' do
          original_priority = task.priority
          service.perform
          expect(task.reload.priority).to eq(original_priority)
        end
      end

      context 'when params are blank' do
        let(:actions) { [{ 'action_name' => 'change_priority', 'action_params' => [] }] }

        it 'does not change the priority' do
          original_priority = task.priority
          service.perform
          expect(task.reload.priority).to eq(original_priority)
        end
      end
    end

    context 'send_webhook_event action' do
      let(:webhook_url) { 'https://example.com/kanban-webhook' }
      let(:actions) { [{ 'action_name' => 'send_webhook_event', 'action_params' => [webhook_url] }] }

      it 'enqueues a WebhookJob with the correct url and event payload' do
        expect(WebhookJob).to receive(:perform_later).with(
          webhook_url,
          hash_including(event: "automation_event.#{rule.event_name}", id: task.id)
        )
        service.perform
      end

      context 'when webhook_url is blank' do
        let(:actions) { [{ 'action_name' => 'send_webhook_event', 'action_params' => [] }] }

        it 'does not enqueue a WebhookJob' do
          expect(WebhookJob).not_to receive(:perform_later)
          service.perform
        end
      end
    end

    context 'add_label_to_task action' do
      let(:actions) { [{ 'action_name' => 'add_label_to_task', 'action_params' => %w[vip urgent] }] }

      it 'adds the labels to the task' do
        service.perform
        expect(task.reload.label_list).to include('vip', 'urgent')
      end

      it 'does not duplicate existing labels' do
        task.add_labels(['vip'])
        service.perform
        expect(task.reload.label_list.count('vip')).to eq(1)
      end

      context 'when labels are blank' do
        let(:actions) { [{ 'action_name' => 'add_label_to_task', 'action_params' => [] }] }

        it 'does nothing' do
          expect { service.perform }.not_to change { task.reload.cached_label_list }
        end
      end
    end

    context 'remove_label_from_task action' do
      let(:actions) { [{ 'action_name' => 'remove_label_from_task', 'action_params' => ['vip'] }] }

      before { task.add_labels(%w[vip premium support]) }

      it 'removes only the specified label' do
        service.perform
        expect(task.reload.label_list).not_to include('vip')
      end

      it 'preserves other labels' do
        service.perform
        expect(task.reload.label_list).to include('premium', 'support')
      end

      context 'when labels are blank' do
        let(:actions) { [{ 'action_name' => 'remove_label_from_task', 'action_params' => [] }] }

        it 'does nothing' do
          labels_before = task.reload.label_list
          service.perform
          expect(task.reload.label_list).to eq(labels_before)
        end
      end
    end

    context 'assign_to_board action' do
      let(:target_board) { create(:kanban_board, account: account) }
      let!(:target_step) { create(:kanban_board_step, board: target_board, position: 0) }
      let(:actions) { [{ 'action_name' => 'assign_to_board', 'action_params' => [target_board.id] }] }

      it 'creates a new task on the target board' do
        expect { service.perform }.to change(Qualifunnel::Kanban::Task, :count).by(1)
      end

      it 'copies the title to the new task' do
        service.perform
        new_task = Qualifunnel::Kanban::Task.where(board: target_board).last
        expect(new_task.title).to eq(task.title)
      end

      it 'copies the priority to the new task' do
        task.update!(priority: :high)
        service.perform
        new_task = Qualifunnel::Kanban::Task.where(board: target_board).last
        expect(new_task.priority).to eq('high')
      end

      it 'places the new task on the first step of the target board' do
        service.perform
        new_task = Qualifunnel::Kanban::Task.where(board: target_board).last
        expect(new_task.board_step).to eq(target_step)
      end

      it 'dispatches events for both the old and new task' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Qualifunnel::Events::Types::KANBAN_TASK_UPDATED, anything, anything
        ).twice
        service.perform
      end

      context 'when the target board is the same as the source board' do
        let(:actions) { [{ 'action_name' => 'assign_to_board', 'action_params' => [board.id] }] }

        it 'does not create a new task' do
          expect { service.perform }.not_to change(Qualifunnel::Kanban::Task, :count)
        end
      end

      context 'when target board does not exist' do
        let(:actions) { [{ 'action_name' => 'assign_to_board', 'action_params' => [999_999] }] }

        it 'does not create a new task' do
          expect { service.perform }.not_to change(Qualifunnel::Kanban::Task, :count)
        end
      end
    end

    context 'when an unknown action is invoked' do
      let(:actions) { [{ 'action_name' => 'nonexistent_action', 'action_params' => [] }] }

      it 'captures the exception without raising' do
        expect { service.perform }.not_to raise_error
        expect(ChatwootExceptionTracker).to have_received(:new)
      end
    end

    context 'Current context cleanup' do
      it 'sets Current.executed_by to the rule during execution' do
        captured = nil
        allow(task).to receive(:reload) do
          captured = Current.executed_by
          task
        end
        service.perform
        expect(captured).to eq(rule)
      end

      it 'resets Current after execution' do
        service.perform
        expect(Current.executed_by).to be_nil
      end

      it 'resets Current even when an action raises' do
        allow(task).to receive(:reload).and_raise(StandardError, 'boom')
        service.perform rescue nil
        expect(Current.executed_by).to be_nil
      end
    end
  end
end
