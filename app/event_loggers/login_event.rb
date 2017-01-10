require "porch"
require_relative "login_event/find_course_membership"
require_relative "login_event/log_job_starting"
require_relative "login_event/log_job_ended"
require_relative "login_event/update_last_login"
require_relative "login_event/record_login_event"

#TODO: Log an error if one occurs (implement rescue_from?)
#TODO: Add log vs. log later

module EventLoggers
  class LoginEvent
    include Porch::Organizer

    attr_accessor :logger

    def initialize(logger)
      @logger = logger
    end

    def log(data)
      with(data.merge(created_at: Time.now, logger: logger)) do |chain|
        chain.add LogJobStarting
        chain.add FindCourseMembership
        chain.add UpdateLastLogin
        chain.add RecordLoginEvent
        chain.add LogJobEnded
      end
    end
  end
end
