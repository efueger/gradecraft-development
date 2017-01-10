module EventLoggers
  class LogJobEnded
    def call(context)
      context.guard! { required(:logger).filled }

      logged_data = context.reject { |k| k == :logger }
      context.logger.info "Successfully logged login event with data #{logged_data}"
      context
    end
  end
end