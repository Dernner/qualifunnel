# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Kanban::Boards', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:board) { create(:kanban_board, account: account) }

  before do
    # Stub feature flag validation
    allow_any_instance_of(Account).to receive(:kanban_feature_enabled?).and_return(true)
  end

  describe 'GET /api/v1/accounts/{account.id}/kanban/boards' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/kanban/boards", as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when kanban feature is disabled' do
      before do
        allow_any_instance_of(Account).to receive(:kanban_feature_enabled?).and_return(false)
      end

      it 'returns not_found' do
        get "/api/v1/accounts/#{account.id}/kanban/boards",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authenticated as agent' do
      it 'returns all boards' do
        get "/api/v1/accounts/#{account.id}/kanban/boards",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first['id']).to eq(board.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/kanban/boards/{board.id}' do
    context 'when authenticated as agent' do
      it 'returns the correct board' do
        get "/api/v1/accounts/#{account.id}/kanban/boards/#{board.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(board.id)
        expect(json['name']).to eq(board.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/kanban/boards' do
    let(:valid_params) { { board: { name: 'New Board', description: 'Testing creation' } } }

    context 'when authenticated as administrator' do
      it 'creates a new board' do
        expect do
          post "/api/v1/accounts/#{account.id}/kanban/boards",
               headers: admin.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(Qualifunnel::Kanban::Board, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('New Board')
        expect(json['account_id']).to eq(account.id)
      end

      it 'returns errors with invalid params' do
        post "/api/v1/accounts/#{account.id}/kanban/boards",
             headers: admin.create_new_auth_token,
             params: { board: { name: '' } },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Name can't be blank")
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/kanban/boards/{board.id}' do
    context 'when authenticated as administrator' do
      it 'updates the board attributes' do
        patch "/api/v1/accounts/#{account.id}/kanban/boards/#{board.id}",
              headers: admin.create_new_auth_token,
              params: { board: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(board.reload.name).to eq('Updated Name')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/kanban/boards/{board.id}' do
    context 'when authenticated as administrator' do
      it 'deletes the board' do
        expect do
          delete "/api/v1/accounts/#{account.id}/kanban/boards/#{board.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Qualifunnel::Kanban::Board, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
