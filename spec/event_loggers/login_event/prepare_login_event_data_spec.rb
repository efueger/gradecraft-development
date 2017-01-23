require "porch"
require "active_record_spec_helper"
require "./app/event_loggers/login_event/prepare_login_event_data"

describe EventLoggers::PrepareLoginEventData do
  describe "#call" do
    let(:context) { Porch::Context.new({ course: course, created_at: created_at,
                                         student: user, user: user })}
    let!(:course_membership) { create :student_course_membership }
    let(:course) { course_membership.course }
    let(:created_at) { Time.now }
    let(:user) { course_membership.user }

    it "adds the event data to the context" do
      result = subject.call context

      expect(result.event_data).to eq ({ course_id: course.id,
                                        user_id: user.id,
                                        student_id: user.id,
                                        user_role: "student",
                                        event_type: :login,
                                        created_at: created_at })
    end

    xit "fails if the user is not present"
    xit "fails if the course is not present"
  end
end
