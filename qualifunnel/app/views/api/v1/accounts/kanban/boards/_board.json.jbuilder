json.id board.id
json.name board.name
json.description board.description
json.currency board.currency
json.steps_order board.steps_order
json.settings board.settings
json.created_at board.created_at
json.updated_at board.updated_at
json.total_tasks_count board.tasks.count
json.assigned_inbox_ids board.board_inboxes.pluck(:inbox_id)
json.total_value 0
json.total_weighted_value 0

board_agents = board.agents.to_a
json.assigned_agents board_agents do |agent|
  json.id agent.id
  json.name agent.name
  json.avatar_url agent.avatar_url
end

board_steps = board.ordered_steps.to_a
json.steps_summary board_steps do |step|
  json.id step.id
  json.name step.name
  json.color step.color
  json.tasks_count step.tasks.count
  json.completed step.completed
  json.cancelled step.cancelled
end
