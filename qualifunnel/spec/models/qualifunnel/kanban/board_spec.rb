# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifunnel::Kanban::Board, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to has_many(:steps).dependent(:destroy).order(:position) }
    it { is_expected.to has_many(:tasks).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    describe 'uniqueness' do
      subject { create(:kanban_board) }

      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id).case_insensitive }
    end
  end

  describe 'store accessors' do
    it 'allows reading and writing settings accessors' do
      board = build(:kanban_board)
      expect(board.default_view).to be_nil

      board.default_view = 'list'
      expect(board.default_view).to eq('list')
      expect(board.settings['default_view']).to eq('list')
    end
  end

  describe 'scopes' do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let!(:board1) { create(:kanban_board, account: account1, updated_at: 2.days.ago) }
    let!(:board2) { create(:kanban_board, account: account1, updated_at: 1.day.ago) }
    let!(:board3) { create(:kanban_board, account: account2, updated_at: Time.current) }

    describe '.for_account' do
      it 'returns boards belonging only to the specified account' do
        expect(described_class.for_account(account1.id)).to contain_exactly(board1, board2)
        expect(described_class.for_account(account2.id)).to contain_exactly(board3)
      end
    end

    describe '.recent' do
      it 'returns boards ordered by updated_at descending' do
        expect(described_class.recent).to eq([board3, board2, board1])
      end
    end
  end
end
