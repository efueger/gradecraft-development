require "active_job"
require "active_record_spec_helper"
require "./app/jobs/application_job"
require "./app/jobs/record_login_event_job"

RSpec.describe RecordLoginEventJob do
  it "enqueues on the login event logger queue" do
    expect(subject.queue_name).to eq "login_event_logger"
  end

  describe "#perform" do
    let(:data) { { some: :blah } }
    let(:logger) { double(:logger) }

    it "logs a start message" do
      expect(logger).to receive(:info).with \
        "Starting LoginEventLogger with data #{data}"

      described_class.perform_now data, logger
    end

    xit "adds a login event to analytics for the user and course"
    xit "updates the course membership's last login timestamp"
  end
end
