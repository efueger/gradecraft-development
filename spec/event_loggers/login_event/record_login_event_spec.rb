require "porch"
require "./app/event_loggers/login_event/record_login_event"

describe EventLoggers::RecordLoginEvent do
  describe "#call" do
    let(:data) {{ last_login_at: Time.now,
                  course: double(:course),
                  user: double(:user),
                  student: nil,
                  user_role: "student",
                  created_at: Time.now }}
    let(:context) { Porch::Context.new(data) }
    let(:result) { double(:event_result, valid?: true) }

    it "records a login event metric" do
      expect(Analytics::LoginEvent).to receive(:create).with(context).and_return result

      subject.call context
    end

    it "fails if the user role is not present" do
      context.delete :user_role

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the login event did not succeed" do
      allow(result).to receive(:valid?).and_return false
      allow(Analytics::LoginEvent).to receive(:create).and_return result

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }
      expect(result).to be_failure
    end
  end
end
