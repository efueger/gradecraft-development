class EventLoggerJob < ApplicationJob
  queue_as :event_logger

  def perform(klass, method, *params)
    klass.constantize.new.send(method, *params)
  end
end
