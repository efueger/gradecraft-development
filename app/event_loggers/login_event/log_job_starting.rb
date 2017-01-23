module EventLoggers
  class LogJobStarting
    def call(context)
      context.guard! do
        required(:event_data).filled
        required(:logger).filled
      end

      context.logger.info "Starting LoginEventLogger with data #{context.event_data}"
      context
    end
  end
end
