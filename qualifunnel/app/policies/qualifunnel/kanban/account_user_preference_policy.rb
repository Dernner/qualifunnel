# frozen_string_literal: true

module Qualifunnel
  module Kanban
    class AccountUserPreferencePolicy < ApplicationPolicy
      def update?
        member?
      end
    end
  end
end
