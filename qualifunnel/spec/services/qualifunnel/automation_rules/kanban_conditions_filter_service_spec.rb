# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::AutomationRules::KanbanConditionsFilterService do
  let(:account) { create(:account) }
  let(:board) { create(:kanban_board, account: account) }
  let(:step) { create(:kanban_board_step, board: board) }
  let(:task) { create(:kanban_task, account: account, board: board, board_step: step) }

  let(:rule) do
    instance_double(AutomationRule, id: 1, active?: true, account_id: account.id, conditions: conditions)
  end
  let(:conditions) { [] }

  subject(:service) { described_class.new(rule, task) }

  describe '#perform' do
    context 'rule validity checks' do
      context 'when the rule is inactive' do
        let(:rule) { instance_double(AutomationRule, active?: false, account_id: account.id, conditions: []) }

        it 'returns false' do
          expect(service.perform).to be(false)
        end
      end

      context 'when the rule belongs to a different account' do
        let(:other_account) { create(:account) }
        let(:rule) { instance_double(AutomationRule, active?: true, account_id: other_account.id, conditions: []) }

        it 'returns false' do
          expect(service.perform).to be(false)
        end
      end
    end

    context 'with no conditions' do
      let(:conditions) { [] }

      it 'returns true' do
        expect(service.perform).to be(true)
      end
    end

    context 'kanban_board_id condition' do
      let(:other_board) { create(:kanban_board, account: account) }
      let(:other_step) { create(:kanban_board_step, board: other_board) }
      let(:other_task) { create(:kanban_task, account: account, board: other_board, board_step: other_step) }

      context 'with equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'kanban_board_id', filter_operator: 'equal_to', values: [board.id.to_s] }]
        end

        it 'returns true when the task is on the specified board' do
          expect(service.perform).to be(true)
        end

        it 'returns false when the task is on a different board' do
          expect(described_class.new(rule, other_task).perform).to be(false)
        end
      end

      context 'with not_equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'kanban_board_id', filter_operator: 'not_equal_to', values: [board.id.to_s] }]
        end

        it 'returns false when the task is on the excluded board' do
          expect(service.perform).to be(false)
        end

        it 'returns true when the task is on a different board' do
          expect(described_class.new(rule, other_task).perform).to be(true)
        end
      end

      context 'with an unknown operator' do
        let(:conditions) do
          [{ attribute_key: 'kanban_board_id', filter_operator: 'contains', values: [board.id.to_s] }]
        end

        it 'returns true (passthrough for unsupported operators)' do
          expect(service.perform).to be(true)
        end
      end
    end

    context 'kanban_step_id condition' do
      let(:other_step) { create(:kanban_board_step, board: board, position: 1) }

      context 'with equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'kanban_step_id', filter_operator: 'equal_to', values: [step.id.to_s] }]
        end

        it 'returns true when the task is on the specified step' do
          expect(service.perform).to be(true)
        end

        it 'returns false when the task is on a different step' do
          task.update!(board_step: other_step)
          expect(service.perform).to be(false)
        end
      end

      context 'with not_equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'kanban_step_id', filter_operator: 'not_equal_to', values: [step.id.to_s] }]
        end

        it 'returns false when the task is on the excluded step' do
          expect(service.perform).to be(false)
        end

        it 'returns true when the task is on a different step' do
          task.update!(board_step: other_step)
          expect(service.perform).to be(true)
        end
      end
    end

    context 'assignee_id condition' do
      let(:agent) { create(:user, account: account) }
      let(:other_agent) { create(:user, account: account) }

      context 'with equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'assignee_id', filter_operator: 'equal_to', values: [agent.id.to_s] }]
        end

        it 'returns true when the specified agent is assigned' do
          task.agents << agent
          expect(service.perform).to be(true)
        end

        it 'returns false when the specified agent is not assigned' do
          expect(service.perform).to be(false)
        end
      end

      context 'with not_equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'assignee_id', filter_operator: 'not_equal_to', values: [agent.id.to_s] }]
        end

        it 'returns false when the excluded agent is assigned' do
          task.agents << agent
          expect(service.perform).to be(false)
        end

        it 'returns true when the excluded agent is not assigned' do
          task.agents << other_agent
          expect(service.perform).to be(true)
        end
      end

      context 'with is_present operator' do
        let(:conditions) do
          [{ attribute_key: 'assignee_id', filter_operator: 'is_present', values: [] }]
        end

        it 'returns true when the task has at least one agent' do
          task.agents << agent
          expect(service.perform).to be(true)
        end

        it 'returns false when the task has no agents' do
          expect(service.perform).to be(false)
        end
      end

      context 'with is_not_present operator' do
        let(:conditions) do
          [{ attribute_key: 'assignee_id', filter_operator: 'is_not_present', values: [] }]
        end

        it 'returns true when the task has no agents' do
          expect(service.perform).to be(true)
        end

        it 'returns false when the task has at least one agent' do
          task.agents << agent
          expect(service.perform).to be(false)
        end
      end
    end

    context 'inbox_id condition' do
      let(:inbox) { create(:inbox, account: account) }
      let(:contact) { create(:contact, account: account) }
      let!(:conversation) do
        create(:conversation, account: account, inbox: inbox, contact: contact).tap do |c|
          c.update_column(:kanban_task_id, task.id)
        end
      end

      context 'with equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'inbox_id', filter_operator: 'equal_to', values: [inbox.id.to_s] }]
        end

        it 'returns true when a conversation belongs to the specified inbox' do
          expect(service.perform).to be(true)
        end

        it 'returns false when no conversation belongs to the specified inbox' do
          other_inbox = create(:inbox, account: account)
          conditions_with_other = [
            { attribute_key: 'inbox_id', filter_operator: 'equal_to', values: [other_inbox.id.to_s] }
          ]
          rule_with_other = instance_double(AutomationRule, id: 1, active?: true, account_id: account.id,
                                                            conditions: conditions_with_other)
          expect(described_class.new(rule_with_other, task).perform).to be(false)
        end
      end

      context 'with not_equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'inbox_id', filter_operator: 'not_equal_to', values: [inbox.id.to_s] }]
        end

        it 'returns false when a conversation is in the excluded inbox' do
          expect(service.perform).to be(false)
        end
      end

      context 'with is_present operator' do
        let(:conditions) do
          [{ attribute_key: 'inbox_id', filter_operator: 'is_present', values: [] }]
        end

        it 'returns true when the task has at least one conversation' do
          expect(service.perform).to be(true)
        end

        it 'returns false when the task has no conversations' do
          conversation.update_column(:kanban_task_id, nil)
          expect(service.perform).to be(false)
        end
      end

      context 'with is_not_present operator' do
        let(:conditions) do
          [{ attribute_key: 'inbox_id', filter_operator: 'is_not_present', values: [] }]
        end

        it 'returns false when the task has conversations' do
          expect(service.perform).to be(false)
        end

        it 'returns true when the task has no conversations' do
          conversation.update_column(:kanban_task_id, nil)
          expect(service.perform).to be(true)
        end
      end
    end

    context 'priority condition' do
      before { task.update!(priority: :high) }

      context 'with equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'priority', filter_operator: 'equal_to', values: ['high'] }]
        end

        it 'returns true when the task priority matches' do
          expect(service.perform).to be(true)
        end

        it 'returns false when the task priority does not match' do
          task.update!(priority: :low)
          expect(service.perform).to be(false)
        end
      end

      context 'with not_equal_to operator' do
        let(:conditions) do
          [{ attribute_key: 'priority', filter_operator: 'not_equal_to', values: ['high'] }]
        end

        it 'returns false when the task priority matches the excluded value' do
          expect(service.perform).to be(false)
        end

        it 'returns true when the task priority does not match the excluded value' do
          task.update!(priority: :low)
          expect(service.perform).to be(true)
        end
      end
    end

    context 'with an unknown attribute_key' do
      let(:conditions) do
        [{ attribute_key: 'unknown_field', filter_operator: 'equal_to', values: ['anything'] }]
      end

      it 'returns true (passthrough)' do
        expect(service.perform).to be(true)
      end
    end

    context 'with multiple conditions (all must match)' do
      let(:agent) { create(:user, account: account) }
      let(:conditions) do
        [
          { attribute_key: 'kanban_board_id', filter_operator: 'equal_to', values: [board.id.to_s] },
          { attribute_key: 'assignee_id', filter_operator: 'is_present', values: [] }
        ]
      end

      it 'returns false when any condition fails' do
        expect(service.perform).to be(false)
      end

      it 'returns true when all conditions pass' do
        task.agents << agent
        expect(service.perform).to be(true)
      end
    end

    context 'when an error occurs during evaluation' do
      let(:conditions) do
        [{ attribute_key: 'kanban_board_id', filter_operator: 'equal_to', values: [board.id.to_s] }]
      end

      before do
        allow(task).to receive(:board_id).and_raise(StandardError, 'unexpected error')
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
      end

      it 'returns false' do
        expect(service.perform).to be(false)
      end

      it 'logs the error' do
        service.perform
        expect(Rails.logger).to have_received(:error).with(/unexpected error/)
      end
    end
  end
end
