module EventLoggers
  class FindCourseMembership
    def call(context)
      context[:course_membership] = nil

      context.next do
        required(:course).filled
        required(:user).filled
      end

      context[:course_membership] = CourseMembership.find_by user_id: context.user.id,
        course_id: context.course.id
      context
    end
  end
end
