require "active_record_spec_helper"
require "./lib/null_logger"
require "./app/event_loggers/login_event"

describe EventLoggers::LoginEvent do
  let(:course) { course_membership.course }
  let(:course_membership) { create :student_course_membership }
  let(:data) do
    {
      course: course,
      user: user,
      user_role: "student",
      student: nil,
      request: request
    }
  end
  let(:logger) { NullLogger.new }
  let(:request) { double(:request) }
  let(:result) { double(:analytics_event, valid?: true) }
  let(:user) { course_membership.user }
  subject { described_class.new logger }

  before { allow(Analytics::LoginEvent).to receive(:create).and_return result }

  describe "#log" do
    it "logs that the job is starting" do
      expect_any_instance_of(EventLoggers::LogJobStarting).to \
        receive(:call).with(hash_including(:logger)).and_call_original

      subject.log data
    end

    it "finds the course membership" do
      expect_any_instance_of(EventLoggers::FindCourseMembership).to \
        receive(:call).with(hash_including(:user, :course)).and_call_original

      subject.log data
    end

    it "updates the last login time" do
      expect_any_instance_of(EventLoggers::UpdateLastLogin).to \
        receive(:call).with(hash_including(:course_membership, :created_at)).and_call_original

      subject.log data
    end

    it "records the analytics event for a login" do
      expect_any_instance_of(EventLoggers::RecordLoginEvent).to \
        receive(:call).and_call_original

      subject.log data
    end

    it "logs that the job has ended" do
      expect_any_instance_of(EventLoggers::LogJobEnded).to \
        receive(:call).with(hash_including(:logger)).and_call_original

      subject.log data
    end
  end
end
