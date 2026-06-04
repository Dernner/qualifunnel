# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class BoardAgentPolicy < ApplicationPolicy
      def index?
        member?
      end

      def create?
        admin?
      end

      def destroy?
        admin?
      end

      def update_agents?
        admin?
      end
    end
  end
end
