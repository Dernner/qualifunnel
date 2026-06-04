# frozen_string_literal: true

# Extends SuperAdmin::AccountFeaturesHelper so that Qualifunnel-specific
# features (backed by qualifunnel_flags instead of feature_flags) appear
# in the Super Admin account features panel alongside standard Chatwoot features.
module Qualifunnel
  module SuperAdminAccountFeaturesExtension
    QUALIFUNNEL_FEATURES = [
      { 'name' => 'kanban', 'display_name' => 'Kanban', 'enabled' => false }
    ].freeze

    def account_features
      super + QUALIFUNNEL_FEATURES
    end
  end
end

Rails.application.config.to_prepare do
  SuperAdmin::AccountFeaturesHelper.singleton_class.prepend(
    Qualifunnel::SuperAdminAccountFeaturesExtension
  )
end
