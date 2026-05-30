# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_board, class: 'Qualifunnel::Kanban::Board' do
    sequence(:name) { |n| "Kanban Board #{n}" }
    description { "Description of Kanban Board" }
    association :account
  end

  factory :kanban_board_step, class: 'Qualifunnel::Kanban::BoardStep' do
    sequence(:name) { |n| "Step #{n}" }
    position { 0 }
    completed { false }
    cancelled { false }
    association :board, factory: :kanban_board
  end

  factory :kanban_task, class: 'Qualifunnel::Kanban::Task' do
    sequence(:title) { |n| "Task #{n}" }
    description { "Description of Task" }
    position { 0 }
    due_date { 1.day.from_now }
    association :account
    association :board, factory: :kanban_board
    association :board_step, factory: :kanban_board_step
  end
end
