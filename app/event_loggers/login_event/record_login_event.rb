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

      data = {
        course_id: context.course.id,
        user_id: context.user.id,
        student_id: context.student.try(:id),
        user_role: context.user_role,
        last_login_at: context.last_login_at,
        event_type: :login,
        created_at: Time.now
      }
      result = Analytics::LoginEvent.create(data)

      unless result.valid?
        context.fail!(Porch::HumanError.new(result.errors).message)
      end
      context
    end
  end
end
