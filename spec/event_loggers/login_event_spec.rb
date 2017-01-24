require "rails_spec_helper"

describe EventLoggers::LoginEvent do
  let(:course) { course_membership.course }
  let(:course_membership) { create :student_course_membership }
  let(:data) do
    {
      course: course,
      user: user,
      user_role: "student",
      student: nil
    }
  end
  let(:logger) { NullLogger.new }
  let(:result) { double(:analytics_event, valid?: true) }
  let(:user) { course_membership.user }
  subject { described_class.new logger }

  before { allow(Analytics::LoginEvent).to receive(:create).and_return result }

  describe "#log" do
    it "prepares the event data" do
      expect_any_instance_of(EventLoggers::PrepareLoginEventData).to \
        receive(:call).with(hash_including(:course, :user)).and_call_original

      subject.log data
    end

    it "logs that the job is starting" do
      expect_any_instance_of(EventLoggers::LogJobStarting).to receive(:call).and_call_original

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
      expect_any_instance_of(EventLoggers::LogJobEnded).to receive(:call).and_call_original

      subject.log data
    end
  end

  describe "#log_later" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "queues a job to be run later with the data provided" do
      subject.log_later data

      expect(EventLoggers::Job).to have_been_enqueued
    end
  end
end
