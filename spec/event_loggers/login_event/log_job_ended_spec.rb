require "porch"
require "./lib/null_logger"
require "./app/event_loggers/login_event/log_job_ended"

describe EventLoggers::LogJobEnded do
  describe "#call" do
    let(:context) { Porch::Context.new({ logger: logger }.merge(data)) }
    let(:data) { { blah: :bleh }}
    let(:logger) { NullLogger.new }

    it "logs the ending of the job to the logger" do
      expect(logger).to \
        receive(:info).with "Successfully logged login event with data #{data}"

      subject.call context
    end

    context "without a logger in the context" do
      it "does not try to log and fails the context" do
        context.delete :logger

        expect(logger).to_not receive(:info)

        result = nil
        expect { subject.call context }.to raise_error { |error| result = error.context }

        expect(result).to be_failure
      end
    end
  end
end
