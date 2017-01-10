module EventLoggers
  class FindCourseMembership
    def call(context)
      user_id = context.user.try(:id)
      course_id = context.course.try(:id)

      context[:course_membership] = CourseMembership.find_by user_id: user_id,
        course_id: course_id
      context
    end
  end
end
