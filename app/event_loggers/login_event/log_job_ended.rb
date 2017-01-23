module EventLoggers
  class LogJobEnded
    def call(context)
      context.guard! do
        required(:event_data).filled
        required(:logger).filled
      end

      context.logger.info "Successfully logged login event with data #{context.event_data}"
      context
    end
  end
end
