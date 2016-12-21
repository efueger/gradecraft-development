class RecordLoginEventJob < ApplicationJob
  queue_as :login_event_logger

  def perform(data={}, logger=NilLogger.new)
    logger.info "Starting LoginEventLogger with data #{data}"
  end
end
