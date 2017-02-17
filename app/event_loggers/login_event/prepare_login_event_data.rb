module EventLoggers
  class PrepareLoginEventData
    def call(context)
      context.guard_with_failure do
        required(:course).filled
        required(:user).filled
      end

      context[:user_role] = context.user.role context.course

      context[:event_data] = {
        course_id: context.course.id,
        user_id: context.user.id,
        student_id: context[:student].try(:id),
        user_role: context.user_role,
        event_type: :login,
        created_at: context[:created_at]
      }
      context
    end
  end
end
