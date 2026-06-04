# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class AuditEventJob < ApplicationJob
      queue_as :low

      def perform(account_id:, task_id:, action:, metadata: {}, performed_by_id: nil)
        return if task_id.nil? && !board_level_action?(action)

        Qualifunnel::Kanban::AuditEvent.create!(
          account_id: account_id,
          task_id: task_id,
          action: action,
          metadata: metadata,
          performed_by_id: performed_by_id
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("[Qualifunnel::AuditEventJob] Failed: #{e.message}")
      end

      private

      def board_level_action?(action)
        %w[board_created board_updated board_deleted task_deleted].include?(action)
      end
    end
  end
end
