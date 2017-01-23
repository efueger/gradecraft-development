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

    it "skips the current action if the user is not passed in" do
      context.delete :user

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result.course_membership).to be_nil
    end

    it "skips the current action if the course is not passed in" do
      context.delete :course

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result.course_membership).to be_nil
    end

    it "returns nil if the course membership cannot be found" do
      user = create :user

      result = subject.call context.merge(user: user)

      expect(result.course_membership).to be_nil
    end
  end
end
