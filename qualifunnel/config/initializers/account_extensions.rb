# frozen_string_literal: true

Rails.application.config.to_prepare do
  Account.include Qualifunnel::Concerns::Account
  Account.prepend Qualifunnel::Concerns::AccountFlagInterceptor
  AccountUser.include Qualifunnel::Concerns::AccountUser
  Conversation.include Qualifunnel::Concerns::Conversation
  Inbox.include Qualifunnel::Concerns::Inbox
  Contact.include Qualifunnel::Concerns::Contact
end
