# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class ApplicationPolicy < ::ApplicationPolicy
      def member?
        account_user&.administrator? || account_user&.agent?
      end

      def admin?
        account_user&.administrator?
      end
    end
  end
end
