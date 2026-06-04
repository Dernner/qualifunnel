json.id task.id
json.title task.title
json.description task.description
json.position task.position
json.priority task.priority
json.value task.value
json.due_date task.due_date
json.start_date task.start_date
json.step_changed_at task.step_changed_at
json.cached_label_list task.cached_label_list
json.custom_attributes task.custom_attributes
json.board_id task.board_id
json.board_step_id task.board_step_id
json.created_by_id task.created_by_id
json.created_at task.created_at
json.updated_at task.updated_at

json.agents task.agents do |agent|
  json.id agent.id
  json.name agent.name
end

json.contacts task.contacts do |contact|
  json.id contact.id
  json.name contact.name
end
