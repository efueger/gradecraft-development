require "rails_spec_helper"

describe EventLoggerJob do
  it "enqueues on a generic queue" do
    expect(subject.queue_name).to eq "event_logger"
  end

  describe "#perform" do
    class DummyClass
      def perform(data); end
    end

    let(:data) {{ a: :b }}
    let(:klass) { DummyClass }
    let(:method) { :perform }

    it "calls the method on the class with the data" do
      expect_any_instance_of(klass).to receive(method).with(data)

      described_class.perform_now klass.name, method, data
    end
  end
end
