# frozen_string_literal: true

module Qualifunnel
  module Events
    module Types
      KANBAN_BOARD_CREATED  = 'kanban_board.created'
      KANBAN_BOARD_UPDATED  = 'kanban_board.updated'
      KANBAN_BOARD_DELETED  = 'kanban_board.deleted'

      KANBAN_TASK_CREATED   = 'kanban_task.created'
      KANBAN_TASK_UPDATED   = 'kanban_task.updated'
      KANBAN_TASK_DELETED   = 'kanban_task.deleted'
      KANBAN_TASK_COMPLETED = 'kanban_task.completed'
      KANBAN_TASK_WON       = 'kanban_task.won'
      KANBAN_TASK_LOST      = 'kanban_task.lost'
      KANBAN_TASK_DUE       = 'kanban_task.due'
    end
  end
end
