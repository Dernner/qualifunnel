# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class ProductPolicy < ApplicationPolicy
      def index?
        member?
      end

      def create?
        admin?
      end

      def update?
        admin?
      end

      def destroy?
        admin?
      end
    end
  end
end
