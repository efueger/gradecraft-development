require "analytics"

module EventLoggers
  class RecordLoginEvent
    def call(context)
      context.guard_with_failure do
        required(:event_data).schema do
          required(:course_id).filled
          required(:user_id).filled
        end
      end

      data = context.event_data.merge(last_login_at: context.last_login_at)
      result = Analytics::LoginEvent.create(data)

      unless result.valid?
        context.fail!(Porch::HumanError.new(result.errors).message)
      end
      context
    end
  end
end
