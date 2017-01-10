module EventLoggers
  class UpdateLastLogin
    def call(context)
      context.guard do
        required(:created_at).filled
        required(:course_membership).filled
      end

      context[:last_login_at] = context.course_membership.last_login_at.try(:to_i)
      context.course_membership.update_attributes last_login_at: context.created_at
      context
    end
  end
end
