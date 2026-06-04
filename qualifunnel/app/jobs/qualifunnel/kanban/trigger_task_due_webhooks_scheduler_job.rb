# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TriggerTaskDueWebhooksSchedulerJob < ApplicationJob
      queue_as :scheduled

      def perform
        Qualifunnel::Kanban::Task
          .where('due_date <= ? AND due_date > ?', Time.current, 1.hour.ago)
          .find_each do |task|
            Qualifunnel::Kanban::TriggerTaskDueWebhookJob.perform_later(task.id)
          end
      end
    end
  end
end
