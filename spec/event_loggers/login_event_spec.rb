require "active_record_spec_helper"
require "./lib/analytics"
require "./lib/null_logger"
require "./app/event_loggers/login_event"

describe EventLoggers::LoginEvent do
  let(:course) { course_membership.course }
  let(:course_membership) { create :student_course_membership }
  let(:data) do
    {
      course: course,
      user: user,
      student: nil,
      request: request
    }
  end
  let(:logger) { NullLogger.new }
  let(:request) { double(:request) }
  let(:user) { course_membership.user }
  subject { described_class.new logger }

  describe "#log" do
    it "logs that the job is starting" do
      expect_any_instance_of(LogJobStarting).to \
        receive(:call).with(hash_including(:logger)).and_call_original

      subject.log data
    end

    it "finds the course membership" do
      expect_any_instance_of(FindCourseMembership).to \
        receive(:call).with(hash_including(:user, :course)).and_call_original

      subject.log data
    end

    it "updates the last login time" do
      expect_any_instance_of(UpdateLastLogin).to \
        receive(:call).with(hash_including(:course_membership, :created_at)).and_call_original

      subject.log data
    end

    it "records the analytics event for a login" do
      expect_any_instance_of(RecordAnalyticsEvent).to \
        receive(:call).and_call_original

      subject.log data
    end

    it "logs that the job has ended" do
      expect_any_instance_of(LogJobEnded).to \
        receive(:call).with(hash_including(:logger)).and_call_original

      subject.log data
    end
  end
end
