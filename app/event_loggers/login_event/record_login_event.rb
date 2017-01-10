require "analytics"

module EventLoggers
  class RecordLoginEvent
    def call(context)
      context.guard! do
        required(:course).filled
        required(:user).filled
      end

      context[:user_role] = context.user.role context.course

      context.guard! { required(:user_role).filled }

      result = Analytics::LoginEvent.create(context.merge(event_type: :login))
      context.fail! unless result.valid?
    end
  end
end
