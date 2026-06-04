ActiveRecordQueryTrace.enabled = Rails.env.development? && ENV['QUERY_TRACE'] == 'true'
