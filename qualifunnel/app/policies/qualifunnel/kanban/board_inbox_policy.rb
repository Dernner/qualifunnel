# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class BoardInboxPolicy < ApplicationPolicy
      def index?
        member?
      end

      def create?
        admin?
      end

      def destroy?
        admin?
      end

      def update_inboxes?
        admin?
      end
    end
  end
end
