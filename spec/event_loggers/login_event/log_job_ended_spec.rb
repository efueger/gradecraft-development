require "porch"
require "./app/event_loggers/login_event/log_job_ended"

describe EventLoggers::LogJobEnded do
  describe "#call" do
    let(:context) { Porch::Context.new({ event_data: event_data }) }
    let(:event_data) { { blah: :bleh }}
    let(:rails) { double(logger: double(:logger, info: nil)) }

    before { stub_const("Rails", rails) }

    it "logs the ending of the job to the logger" do
      expect(Rails.logger).to \
        receive(:info).with "Successfully logged LoginEvent with data #{event_data}"

      subject.call context
    end

    it "fails if the event data is not present" do
      context.delete :event_data

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end
  end
end
