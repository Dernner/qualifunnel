json.partial! 'api/v1/accounts/kanban/boards/board', board: @board

json.steps @board.steps.ordered do |step|
  json.id step.id
  json.name step.name
  json.position step.position
  json.completed step.completed
  json.cancelled step.cancelled
  json.probability step.probability
  json.color step.color
  json.description step.description
  json.tasks_count step.tasks_count
end

json.agent_ids @board.board_agents.pluck(:agent_id)
json.inbox_ids @board.board_inboxes.pluck(:inbox_id)
