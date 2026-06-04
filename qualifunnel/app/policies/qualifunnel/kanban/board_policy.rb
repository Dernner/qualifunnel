# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class BoardPolicy < ApplicationPolicy
      # Any account member can list and view boards
      def index?
        member?
      end

      def show?
        member?
      end

      # Only administrators can create, update or delete boards
      def create?
        admin?
      end

      def update?
        admin?
      end

      def update_agents?
        admin?
      end

      def update_inboxes?
        admin?
      end

      def toggle_favorite?
        member?
      end

      def destroy?
        admin?
      end
    end
  end
end
