module EventLoggers
  class LogJobStarting
    def call(context)
      context.guard_with_failure do
        required(:event_data).filled
      end

      Rails.logger.info "Starting LoginEvent with data #{context.event_data}"
      context
    end
  end
end
