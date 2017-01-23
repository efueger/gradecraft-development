module EventLoggers
  class LogJobStarting
    def call(context)
      context.guard! do
        required(:event_data).filled
      end

      Rails.logger.info "Starting LoginEventLogger with data #{context.event_data}"
      context
    end
  end
end
