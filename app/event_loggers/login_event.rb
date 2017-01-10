require "porch"
require_relative "login_event/find_course_membership"
require_relative "login_event/log_job_starting"
require_relative "login_event/log_job_ended"

class RecordAnalyticsEvent
  def call(context)
    # TODO: Need the user role. Guard against it not being there by using a param required
    Analytics::LoginEvent.create(context)
    # TODO: Check if the result is valid? and fail the context if not
  end
end

class UpdateLastLogin
  # TODO: Require CourseMembership
  # TODO: Require CreatedAt
  def call(context)
    context[:last_login_at] = context[:course_membership].last_login_at.try(:to_i)
    context[:course_membership].update_attributes last_login_at: context[:created_at]
  end
end

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
        chain.add RecordAnalyticsEvent
        chain.add LogJobEnded
      end
    end
  end
end
