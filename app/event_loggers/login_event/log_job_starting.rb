module EventLoggers
  class LogJobStarting
    def call(context)
      context.guard! { required(:logger).filled }

      logged_data = context.reject { |k| k == :logger }
      context.logger.info "Starting LoginEventLogger with data #{logged_data}"
      context
    end
  end
end
