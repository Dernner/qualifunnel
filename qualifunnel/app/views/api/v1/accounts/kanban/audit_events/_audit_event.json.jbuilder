json.id audit_event.id
json.task_id audit_event.task_id
json.action audit_event.action
json.metadata audit_event.metadata
json.created_at audit_event.created_at

json.performed_by do
  if audit_event.performed_by
    json.id audit_event.performed_by.id
    json.name audit_event.performed_by.name
  else
    json.null!
  end
end
