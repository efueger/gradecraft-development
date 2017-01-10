require "analytics"

module EventLoggers
  class RecordLoginEvent
    def call(context)
      context.guard! { required(:user_role).filled }

      result = Analytics::LoginEvent.create(context)
      context.fail! unless result.valid?
    end
  end
end
