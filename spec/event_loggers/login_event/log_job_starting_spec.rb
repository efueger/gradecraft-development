require "porch"
require "./lib/null_logger"
require "./app/event_loggers/login_event/log_job_starting"

describe EventLoggers::LogJobStarting do
  describe "#call" do
    let(:context) { Porch::Context.new({ logger: logger, event_data: event_data }) }
    let(:event_data) { { blah: :bleh }}
    let(:logger) { NullLogger.new }

    it "logs the starting of the job to the logger" do
      expect(logger).to receive(:info)
        .with "Starting LoginEventLogger with data #{event_data}"

      subject.call context
    end

    it "fails if the event data is not present" do
      context.delete :event_data

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the logger is not present" do
      context.delete :logger

      expect(logger).to_not receive(:info)

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end
  end
end
