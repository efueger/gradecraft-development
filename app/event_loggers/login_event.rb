require "porch"

class FindCourseMembership
  def call(context)
    user_id = context[:user].try(:id)
    course_id = context[:course].try(:id)

    context[:course_membership] = CourseMembership.find_by user_id: user_id, course_id: course_id
  end
end

class LogJobStarting
  def call(context)
    logged_data = context.reject { |k| k == :logger }
    context[:logger].info "Starting LoginEventLogger with data #{logged_data}"
    context
  end
end

class LogJobEnded
  def call(context)
    logged_data = context.reject { |k| k == :logger }
    context[:logger].info "Sucessfully logged login event with data #{logged_data}"
    context
  end
end

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
