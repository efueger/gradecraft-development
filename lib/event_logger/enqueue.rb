module EventLogger
  module Enqueue
    def initialize(event_session={})
      @event_session = event_session
    end
    attr_reader :event_session

    def logger_class
      self.class
    end

    def enqueue_in(time_until_start)
      Resque.enqueue_in(time_until_start, logger_class, event_type, attrs)
    end

    def enqueue_at(scheduled_time)
      Resque.enqueue_at(scheduled_time, logger_class, event_type, attrs)
    end

    def enqueue
      Resque.enqueue(logger_class, event_type, attrs)
    end

    def enqueue_in_with_fallback(time_until_start)
      begin
        # schedule the event for later if Resque is available
        enqueue_in(time_until_start)
      rescue
        # otherwise insert directly into Mongo
        self.perform(event_type, attrs)
      end
    end

    def base_attrs
      {
        course_id: event_session[:course].try(:id),
        user_id: event_session[:user].try(:id),
        student_id: event_session[:student].try(:id),
        user_role: event_session[:user].role(event_session[:course]),
        created_at: Time.zone.now
      }
    end
  end
end
