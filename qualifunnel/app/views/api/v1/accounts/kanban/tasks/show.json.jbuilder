json.partial! 'api/v1/accounts/kanban/tasks/task', task: @task

json.task_products @task.task_products.includes(:product) do |tp|
  json.id tp.id
  json.quantity tp.quantity
  json.unit_price tp.unit_price
  json.discount_percentage tp.discount_percentage
  json.total_price tp.total_price
  json.product do
    json.id tp.product.id
    json.name tp.product.name
    json.unit_price tp.product.unit_price
  end
end

json.conversations_count @task.conversations.count
