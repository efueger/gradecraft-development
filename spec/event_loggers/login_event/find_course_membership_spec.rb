require "porch"
require "active_record_spec_helper"
require "./app/event_loggers/login_event/find_course_membership"

describe EventLoggers::FindCourseMembership do
  describe "#call" do
    let(:context) { Porch::Context.new({ course: course, user: user })}
    let!(:course_membership) { create :student_course_membership }
    let(:course) { course_membership.course }
    let(:user) { course_membership.user }

    it "finds the course membership for a user and course" do
      result = subject.call context

      expect(result.course_membership).to eq course_membership
    end

    it "returns nil if the course membership cannot be found" do
      user = create :user

      result = subject.call context.merge(user: user)

      expect(result.course_membership).to be_nil
    end

    it "returns nil if the course was not passed in" do
      result = subject.call context.merge(course: nil)

      expect(result.course_membership).to be_nil
    end
  end
end
