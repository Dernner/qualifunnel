# frozen_string_literal: true

module Qualifunnel
  class KanbanListener < BaseListener
    include Singleton
    include Qualifunnel::Events::Types

    def kanban_board_created(event)
      board = event.data[:board]
      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: board.account_id,
        task_id: nil,
        action: 'board_created',
        metadata: { board_id: board.id, board_name: board.name },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_board_updated(event)
      board = event.data[:board]
      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: board.account_id,
        task_id: nil,
        action: 'board_updated',
        metadata: { board_id: board.id, changes: event.data[:changed_attributes] },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_task_created(event)
      task = event.data[:task]
      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: task.account_id,
        task_id: task.id,
        action: 'task_created',
        metadata: { board_id: task.board_id, step_id: task.board_step_id },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_task_updated(event)
      task = event.data[:task]
      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: task.account_id,
        task_id: task.id,
        action: 'task_updated',
        metadata: { changes: event.data[:changed_attributes] },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_task_completed(event)
      task = event.data[:task]
      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: task.account_id,
        task_id: task.id,
        action: 'task_completed',
        metadata: { board_id: task.board_id },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_task_deleted(event)
      task_data = event.data[:task_data]
      return if task_data[:id].blank?

      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: task_data[:account_id],
        task_id: nil,
        action: 'task_deleted',
        metadata: { task_id: task_data[:id], board_id: task_data[:board_id] },
        performed_by_id: event.data[:performed_by_id]
      )
    end

    def kanban_task_due(event)
      task = event.data[:task]
      return if task.nil?

      Qualifunnel::Kanban::AuditEventJob.perform_later(
        account_id: task.account_id,
        task_id: task.id,
        action: 'task_due',
        metadata: { board_id: task.board_id, due_date: task.due_date }
      )
    end
  end
end
