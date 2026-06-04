# frozen_string_literal: true

class Qualifunnel::AutomationRules::KanbanActionService # rubocop:disable Metrics/ClassLength
  def initialize(rule, account, task)
    @rule = rule
    @account = account
    @task = task
    Current.executed_by = rule
  end

  def perform
    @rule.actions.each do |action|
      @task.reload
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def assign_agent(agent_ids = [])
    return if agent_ids.blank?

    agent_id = agent_ids.first
    return unassign_agent if agent_id == 'nil'

    agent = @account.users.find_by(id: agent_id)
    return if agent.blank?
    return unless @task.board.agents.exists?(id: agent.id)

    @task.task_agents.find_or_create_by!(agent: agent)

    assign_agent_to_conversations(agent) if @task.conversations.any?
  end

  def move_to_step(step_ids = [])
    return if step_ids.blank?

    step = @task.board.steps.find_by(id: step_ids.first)
    return if step.blank?

    @task.update!(board_step: step)
  end

  def mark_completed(_params = nil)
    completed_step = @task.board.completed_step
    return if completed_step.blank?

    @task.update!(board_step: completed_step)
  end

  def mark_cancelled(_params = nil)
    cancelled_step = @task.board.ordered_steps.find_by(cancelled: true)
    return if cancelled_step.blank?

    @task.update!(board_step: cancelled_step)
  end

  def change_priority(priority_params = [])
    return if priority_params.blank?

    priority = priority_params.first
    return unless Qualifunnel::Kanban::Task::PRIORITIES.include?(priority)

    @task.update!(priority: priority)
  end

  def send_webhook_event(webhook_url)
    return if webhook_url.blank?

    payload = @task.push_event_data.merge(event: "automation_event.#{@rule.event_name}")
    WebhookJob.perform_later(webhook_url.first, payload)
  end

  def send_message(message)
    return if message.blank?

    @task.conversations.each do |conversation|
      next if conversation_a_tweet?(conversation)

      params = { content: message.first, private: false, content_attributes: { automation_rule_id: @rule.id } }
      Messages::MessageBuilder.new(nil, conversation, params).perform
    end
  end

  def add_label_to_task(labels)
    return if labels.blank?

    @task.add_labels(labels)
  end

  def remove_label_from_task(labels)
    return if labels.blank?

    remaining_labels = @task.label_list - labels
    @task.update!(cached_label_list: remaining_labels.join(','))
  end

  def add_private_note(message)
    return if message.blank?

    @task.conversations.each do |conversation|
      next if conversation_a_tweet?(conversation)

      params = { content: message.first, private: true, content_attributes: { automation_rule_id: @rule.id } }
      Messages::MessageBuilder.new(nil, conversation.reload, params).perform
    end
  end

  def mute_conversation(params = nil)
    delegate_to_conversations(:mute_conversation, params)
  end

  def snooze_conversation(params = nil)
    delegate_to_conversations(:snooze_conversation, params)
  end

  def resolve_conversation(params = nil)
    delegate_to_conversations(:resolve_conversation, params)
  end

  def open_conversation(params = nil)
    delegate_to_conversations(:open_conversation, params)
  end

  def assign_team(params = [])
    delegate_to_conversations(:assign_team, params)
  end

  def delegate_to_conversations(action_name, params)
    @task.conversations.each do |conversation|
      ActionService.new(conversation).send(action_name, params)
    end
  end

  def assign_to_board(board_ids = [])
    return if board_ids.blank?

    board = find_target_board(board_ids.first)
    return if board.blank?
    return if board.id == @task.board_id

    new_task = create_task_on_board(board)
    copy_task_attributes_to(new_task, board)
    dispatch_old_task_update
    dispatch_new_task_update(new_task)
    new_task
  end

  def unassign_agent
    @task.task_agents.destroy_all
  end

  def assign_agent_to_conversations(agent)
    @task.conversations.each do |conversation|
      next if conversation.assignee_id == agent.id
      next unless conversation.inbox.members.exists?(id: agent.id) || @account.administrators.exists?(id: agent.id)

      conversation.update!(assignee_id: agent.id)
    end
  end

  def conversation_a_tweet?(conversation)
    return false if conversation.additional_attributes.blank?

    conversation.additional_attributes['type'] == 'tweet'
  end

  def build_copied_description
    max_length = Qualifunnel::Kanban::Task::DESCRIPTION_MAX_LENGTH
    copied_from_header = I18n.t(
      'kanban.tasks.automation.copied_from_board',
      locale: @account.locale,
      board_name: @task.board.name
    )

    original_description = @task.description.to_s
    return copied_from_header if original_description.blank?

    full_description = "#{copied_from_header}\n\n#{original_description}"
    return full_description if full_description.length <= max_length

    full_description.truncate(max_length)
  end

  def find_target_board(board_id)
    board = @account.kanban_boards.find_by(id: board_id)
    return nil if board.blank?
    return nil if board.id == @task.board_id

    board
  end

  def create_task_on_board(board)
    new_task = Qualifunnel::Kanban::Task.create!(
      account: @account,
      board: board,
      board_step: board.first_step,
      created_by: nil,
      title: @task.title,
      description: build_copied_description,
      priority: @task.priority
    )

    move_conversations_to_task(new_task, board)
    new_task
  end

  def move_conversations_to_task(new_task, board)
    @task.conversations.find_each do |conversation|
      next unless board.includes_inbox?(conversation.inbox_id)

      conversation.update_column(:kanban_task_id, new_task.id) # rubocop:disable Rails/SkipsModelValidations
      Rails.configuration.dispatcher.dispatch(
        Events::Types::CONVERSATION_UPDATED,
        Time.zone.now,
        conversation: conversation.reload
      )
    end
  end

  def copy_task_attributes_to(new_task, board)
    new_task.add_labels(@task.label_list) if @task.label_list.present?

    @task.agents.each do |agent|
      new_task.task_agents.create!(agent: agent) if board.agents.exists?(id: agent.id)
    end
  end

  def dispatch_old_task_update
    @task.reload
    Rails.configuration.dispatcher.dispatch(
      Qualifunnel::Events::Types::KANBAN_TASK_UPDATED,
      Time.zone.now,
      task: @task,
      changed_attributes: {}
    )
  end

  def dispatch_new_task_update(new_task)
    new_task.reload
    Rails.configuration.dispatcher.dispatch(
      Qualifunnel::Events::Types::KANBAN_TASK_UPDATED,
      Time.zone.now,
      task: new_task,
      changed_attributes: {}
    )
  end
end
