module EventLoggers
  class LogJobEnded
    def call(context)
      context.guard_with_failure do
        required(:event_data).filled
      end

      Rails.logger.info "Successfully logged login event with data #{context.event_data}"
      context
    end
  end
end
