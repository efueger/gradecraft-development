require "porch"
require "./app/event_loggers/login_event/record_login_event"

describe EventLoggers::RecordLoginEvent do
  describe "#call" do
    let(:data) {{ last_login_at: Time.now,
                  course: double(:course),
                  user: double(:user, role: "student"),
                  student: nil,
                  created_at: Time.now }}
    let(:context) { Porch::Context.new(data) }
    let(:result) { double(:event_result, valid?: true) }

    it "records a login event metric" do
      event_context = context.merge(event_type: :login, user_role: "student")

      expect(Analytics::LoginEvent).to receive(:create).with(event_context)
        .and_return result

      subject.call context
    end

    it "fails if the user is not present" do
      context.delete :user

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the course is not present" do
      context.delete :course

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the user role is not found" do
      allow(data[:user]).to receive(:role).and_return nil

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the login event did not succeed", focus: true do
      allow(result).to receive(:valid?).and_return false
      allow(result).to receive(:errors).and_return({ email: ["is invalid"] })
      allow(Analytics::LoginEvent).to receive(:create).and_return result

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }
      expect(result).to be_failure
      expect(result.message).to eq "Email is invalid"
    end
  end
end
