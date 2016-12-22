require "rails_spec_helper"

RSpec.describe RecordLoginEventJob do
  it "enqueues on the login event logger queue" do
    expect(subject.queue_name).to eq "login_event_logger"
  end

  describe "#perform" do
    let(:course) { create :course }
    let(:student_course_membership) { create :student_course_membership, course: course }
    let(:data) do
      { event_type: :login,
        created_at: Time.now,
        course_id: course.id,
        user_id: professor.id,
        student_id: student_course_membership.user.id,
        user_role: professor_course_membership.role }
    end
    let(:last_login_at) { 2.days.ago }
    let(:professor_course_membership) do
      create :professor_course_membership, course: course, last_login_at: last_login_at
    end
    let(:professor) { professor_course_membership.user }
    let(:logger) { double(:logger, info: nil) }
    let(:valid_analytics_event) { double(:analytics_event, valid?: true) }

    before do
      allow(Analytics::LoginEvent).to receive(:create).and_return valid_analytics_event
    end

    it "logs a start message" do
      expect(logger).to receive(:info).with \
        "Starting LoginEventLogger with data #{data}"

      described_class.perform_now data, logger
    end

    it "logs a successful outcome message" do
      expect(logger).to receive(:info).with \
        "Successfully logged login event data "\
        "#{data.merge(last_login_at: last_login_at.to_i)}"

      described_class.perform_now data, logger
    end

    it "adds a login event to analytics for the user and course" do
      expect(Analytics::LoginEvent).to receive(:create)
        .with(data.merge(last_login_at: last_login_at.to_i))
        .and_return valid_analytics_event

      described_class.perform_now data, logger
    end

    it "updates the course membership's last login timestamp" do
      described_class.perform_now data, logger

      expect(professor_course_membership.reload.last_login_at).to eq data[:created_at]
    end

    context "without a course membership found" do
    end

    context "without a valid response from the analyitics event" do
    end
  end
end
