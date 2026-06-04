# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class TaskPolicy < ApplicationPolicy
      def index?
        member?
      end

      def show?
        member?
      end

      def create?
        member?
      end

      def update?
        member?
      end

      def destroy?
        member?
      end

      def move?
        member?
      end
    end
  end
end
