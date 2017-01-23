require "porch"
require_relative "login_event/find_course_membership"
require_relative "login_event/log_job_starting"
require_relative "login_event/log_job_ended"
require_relative "login_event/update_last_login"
require_relative "login_event/record_login_event"

#TODO: Log an error if one occurs (implement rescue_from?)

module EventLoggers
  class LoginEvent
    include Porch::Organizer

    attr_accessor :logger

    def initialize(logger)
      @logger = logger
    end

    def log(data)
      with(merged_data(data)) do |chain|
        steps.insert(3, RecordLoginEvent).each { |step| chain.add step }
      end
    end

    def log_later(data)
    end

    private

    def merged_data(data)
      data.merge(created_at: Time.now, logger: logger)
    end

    def steps
      [LogJobStarting,
       FindCourseMembership,
       UpdateLastLogin,
       # RecordLoginEvent will be inserted here with appropriate parameters
       LogJobEnded]
    end
  end
end
