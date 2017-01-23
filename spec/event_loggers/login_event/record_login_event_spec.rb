require "porch"
require "./app/event_loggers/login_event/record_login_event"

describe EventLoggers::RecordLoginEvent do
  describe "#call" do
    let(:context) { Porch::Context.new(event_data: event_data, last_login_at: last_login) }
    let(:event_data) {{ course_id: 123,
                        user_id: 456,
                        student_id: nil,
                        user_role: "admin",
                        event_type: :login,
                        created_at: Time.now }}
    let(:last_login) { Time.now.to_i }
    let(:result) { double(:event_result, valid?: true) }

    it "records a login event metric" do
      data = event_data.merge(last_login_at: last_login)

      expect(Analytics::LoginEvent).to receive(:create).with(data)
        .and_return result

      subject.call context
    end

    it "fails if the event data is not present" do
      context.delete :event_data

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the course id is not present" do
      event_data.delete :course_id

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the user id is not present" do
      event_data.delete :user_id

      result = nil
      expect { subject.call context }.to raise_error { |error| result = error.context }

      expect(result).to be_failure
    end

    it "fails if the login event did not succeed" do
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
