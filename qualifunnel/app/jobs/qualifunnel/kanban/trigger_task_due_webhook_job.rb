# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TriggerTaskDueWebhookJob < ApplicationJob
      queue_as :low

      def perform(task_id)
        task = Qualifunnel::Kanban::Task.find_by(id: task_id)
        return if task.nil? || task.due_date.nil?
        return unless task.due_date <= Time.current

        Dispatcher.dispatch(
          Qualifunnel::Events::Types::KANBAN_TASK_DUE,
          Time.current,
          { task: task, account: task.account }
        )
      end
    end
  end
end
