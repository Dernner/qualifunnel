class AutomationRuleListener < BaseListener
  def conversation_updated(event)
    process_conversation_event(event, 'conversation_updated')
  end

  def conversation_created(event)
    process_conversation_event(event, 'conversation_created')
  end

  def conversation_opened(event)
    process_conversation_event(event, 'conversation_opened')
  end

  def conversation_resolved(event)
    process_conversation_event(event, 'conversation_resolved')
  end

  def kanban_task_created(event)
    process_task_event(event, 'kanban_task_created')
  end

  def kanban_task_updated(event)
    process_task_event(event, 'kanban_task_updated')
  end

  def kanban_task_won(event)
    process_task_event(event, 'kanban_task_won')
  end

  def kanban_task_lost(event)
    process_task_event(event, 'kanban_task_lost')
  end

  def message_created(event)
    message = event.data[:message]

    return if ignore_message_created_event?(event)

    account = message.try(:account)
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?('message_created', account)

    rules = current_account_rules('message_created', account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation,
                                                                        { message: message, changed_attributes: changed_attributes }).perform
      ::AutomationRules::ActionService.new(rule, account, message.conversation).perform if conditions_match.present?
    end
  end

  private

  def process_conversation_event(event, event_name)
    return if performed_by_automation?(event)

    auto_reply_skip_events = %w[conversation_created conversation_opened]
    return if auto_reply_skip_events.include?(event_name) && ignore_auto_reply_event?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    changed_attributes = event.data[:changed_attributes]

    return unless rule_present?(event_name, account)

    rules = current_account_rules(event_name, account)

    rules.each do |rule|
      conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, conversation, { changed_attributes: changed_attributes }).perform
      AutomationRules::ActionService.new(rule, account, conversation).perform if conditions_match.present?
    end
  end

  def process_task_event(event, event_name)
    task = event.data[:task]
    account = task&.account
    return unless rule_present?(event_name, account)

    rules = current_account_rules(event_name, account)
    rules.each do |rule|
      next unless task_matches_conditions?(rule, task)

      rule.actions.each do |action|
        action = action.with_indifferent_access
        next unless action[:action_name] == 'send_webhook_event'

        payload = task.push_event_data.merge(event: "automation_event.#{event_name}")
        WebhookJob.perform_later(action[:action_params][0], payload)
      end
    end
  end

  def task_matches_conditions?(rule, task)
    return true if rule.conditions.blank?

    results = rule.conditions.map do |condition|
      condition = condition.with_indifferent_access
      attr_key  = condition[:attribute_key]
      operator  = condition[:filter_operator]
      values    = Array(condition[:values]).map(&:to_s)

      case attr_key
      when 'board_id'
        task_condition_match(task.board_id.to_s, operator, values)
      when 'assignee_id'
        task.agents.any? { |a| task_condition_match(a.id.to_s, operator, values) }
      when 'priority'
        task_condition_match(task.priority.to_s, operator, values)
      when 'inbox_id'
        task.conversations.any? { |c| task_condition_match(c.inbox_id.to_s, operator, values) }
      else
        true
      end
    end

    results.all?
  end

  def task_condition_match(value, operator, values)
    case operator
    when 'equal_to', 'contains' then values.include?(value)
    when 'not_equal_to', 'does_not_contain' then !values.include?(value)
    else true
    end
  end

  def rule_present?(event_name, account)
    return if account.blank?

    current_account_rules(event_name, account).any?
  end

  def current_account_rules(event_name, account)
    AutomationRule.where(
      event_name: event_name,
      account_id: account.id,
      active: true
    )
  end

  def performed_by_automation?(event)
    event.data[:performed_by].present? && event.data[:performed_by].instance_of?(AutomationRule)
  end

  def ignore_auto_reply_event?(event)
    conversation = event.data[:conversation]
    conversation.additional_attributes['auto_reply'].present?
  end

  def ignore_message_created_event?(event)
    message = event.data[:message]
    performed_by_automation?(event) || message.activity? || message.auto_reply_email?
  end
end
