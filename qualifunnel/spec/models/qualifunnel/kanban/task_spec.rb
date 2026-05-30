# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::Kanban::Task, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:board_step) }
    it { is_expected.to has_many(:conversations).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:board1) { create(:kanban_board, account: account1) }
    let(:board2) { create(:kanban_board, account: account2) }
    let(:step1) { create(:kanban_board_step, board: board1, position: 0) }
    let(:step2) { create(:kanban_board_step, board: board1, position: 1) }

    let!(:task1) do
      create(:kanban_task,
             account: account1,
             board: board1,
             board_step: step1,
             position: 2,
             due_date: 1.day.ago)
    end

    let!(:task2) do
      create(:kanban_task,
             account: account1,
             board: board1,
             board_step: step2,
             position: 1,
             due_date: 1.day.from_now)
    end

    let!(:task3) do
      create(:kanban_task,
             account: account2,
             board: board2,
             position: 0,
             due_date: 5.days.from_now)
    end

    describe '.for_account' do
      it 'returns tasks for the specified account' do
        expect(described_class.for_account(account1.id)).to contain_exactly(task1, task2)
        expect(described_class.for_account(account2.id)).to contain_exactly(task3)
      end
    end

    describe '.for_board' do
      it 'returns tasks for the specified board' do
        expect(described_class.for_board(board1.id)).to contain_exactly(task1, task2)
        expect(described_class.for_board(board2.id)).to contain_exactly(task3)
      end
    end

    describe '.for_step' do
      it 'returns tasks for the specified step' do
        expect(described_class.for_step(step1.id)).to contain_exactly(task1)
        expect(described_class.for_step(step2.id)).to contain_exactly(task2)
      end
    end

    describe '.ordered' do
      it 'returns tasks ordered by position ascending' do
        expect(described_class.ordered).to eq([task3, task2, task1])
      end
    end

    describe '.overdue' do
      it 'returns tasks where due_date is in the past' do
        expect(described_class.overdue).to contain_exactly(task1)
      end
    end

    describe '.due_soon' do
      it 'returns tasks where due_date is between current time and 3 days from now' do
        expect(described_class.due_soon).to contain_exactly(task2)
      end
    end
  end
end
