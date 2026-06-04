# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class AuditEventPolicy < ApplicationPolicy
      def index?
        member?
      end

      def show?
        member?
      end
    end
  end
end
