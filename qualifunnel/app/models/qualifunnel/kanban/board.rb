# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_boards
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :text
#  settings    :jsonb            not null, default: {}
#  account_id  :bigint           not null
#  currency    :string           default("USD")
#  steps_order :integer          default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Qualifunnel
  module Kanban
    class Board < ApplicationRecord
      self.table_name = 'kanban_boards'

      belongs_to :account

      has_many :steps,
               -> { order(:position) },
               class_name: 'Qualifunnel::Kanban::BoardStep',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      has_many :tasks,
               class_name: 'Qualifunnel::Kanban::Task',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      has_many :board_agents,
               class_name: 'Qualifunnel::Kanban::BoardAgent',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      has_many :agents,
               through: :board_agents,
               class_name: 'User',
               source: :agent

      has_many :board_inboxes,
               class_name: 'Qualifunnel::Kanban::BoardInbox',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      has_many :inboxes,
               through: :board_inboxes,
               class_name: 'Inbox',
               source: :inbox

      has_many :products,
               class_name: 'Qualifunnel::Kanban::Product',
               foreign_key: :board_id,
               dependent: :destroy,
               inverse_of: :board

      validates :name, presence: true
      validates :name, uniqueness: { scope: :account_id, case_sensitive: false }

      store_accessor :settings, :default_view

      scope :for_account, ->(account_id) { where(account_id: account_id) }
      scope :recent, -> { order(updated_at: :desc) }

      def auto_assign_task_to_agent?
        settings['auto_assign_task_to_agent'] == true
      end

      def first_step
        steps.order(:position).first
      end

      def completed_step
        steps.find_by(completed: true)
      end

      def ordered_steps
        return steps.order(:position) if steps_order.blank?

        steps.order(Arel.sql("ARRAY_POSITION(ARRAY[#{steps_order.map(&:to_i).join(',')}]::bigint[], id)"))
      end

      def includes_inbox?(inbox_id)
        board_inboxes.exists?(inbox_id: inbox_id)
      end

      def push_event_data
        {
          id: id,
          name: name,
          description: description,
          currency: currency,
          account_id: account_id,
          created_at: created_at,
          updated_at: updated_at
        }
      end
    end
  end
end
