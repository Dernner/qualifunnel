# frozen_string_literal: true

Rails.application.config.to_prepare do
  AsyncDispatcher.prepend(Module.new do
    def listeners
      super + [Qualifunnel::KanbanListener.instance]
    end
  end)

  SyncDispatcher.prepend(Module.new do
    def listeners
      super + [Qualifunnel::ActionCableListener.instance]
    end
  end)
end
