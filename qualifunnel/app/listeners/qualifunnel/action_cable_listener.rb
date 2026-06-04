# frozen_string_literal: true

module Qualifunnel
  class ActionCableListener < BaseListener
    include Singleton
    include Qualifunnel::Events::Types

    def kanban_board_created(event)
      board = event.data[:board]
      tokens = account_agent_tokens(board.account)
      broadcast(board.account, tokens, KANBAN_BOARD_CREATED, board.push_event_data)
    end

    def kanban_board_updated(event)
      board = event.data[:board]
      tokens = account_agent_tokens(board.account)
      broadcast(board.account, tokens, KANBAN_BOARD_UPDATED, board.push_event_data)
    end

    def kanban_board_deleted(event)
      board_data = event.data[:board_data]
      account = Account.find_by(id: board_data[:account_id])
      return if account.blank?

      tokens = account_agent_tokens(account)
      broadcast(account, tokens, KANBAN_BOARD_DELETED, board_data)
    end

    def kanban_task_created(event)
      task = event.data[:task]
      tokens = board_agent_tokens(task.board)
      broadcast(task.account, tokens, KANBAN_TASK_CREATED, task.push_event_data)
    end

    def kanban_task_updated(event)
      task = event.data[:task]
      tokens = board_agent_tokens(task.board)
      broadcast(task.account, tokens, KANBAN_TASK_UPDATED, task.push_event_data)
    end

    def kanban_task_deleted(event)
      task_data = event.data[:task_data]
      account = Account.find_by(id: task_data[:account_id])
      return if account.blank?

      tokens = account_agent_tokens(account)
      broadcast(account, tokens, KANBAN_TASK_DELETED, task_data)
    end

    private

    def account_agent_tokens(account)
      account.agents.pluck(:pubsub_token) + account.administrators.pluck(:pubsub_token)
    end

    def board_agent_tokens(board)
      if board.board_agents.exists?
        board.agents.pluck(:pubsub_token)
      else
        account_agent_tokens(board.account)
      end
    end

    def broadcast(account, tokens, event_name, data)
      return if tokens.blank?

      payload = data.merge(account_id: account.id)
      payload[:performer] = Current.user&.push_event_data if Current.user.present?
      ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, payload)
    end
  end
end
