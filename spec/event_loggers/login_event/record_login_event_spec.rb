require "porch"
require "./app/event_loggers/login_event/record_login_event"

describe EventLoggers::RecordLoginEvent do
  describe "#call" do
    let(:context) { Porch::Context.new(data) }
    let(:data) {{ course: double(:course, id: 123),
                  last_login_at: Time.now.to_i,
                  user: double(:user, id: 456, role: "student"),
                  student: double(:student, id: 789),
                  created_at: Time.now }}
    let(:result) { double(:event_result, valid?: true) }

    it "records a login event metric" do
      event_data = {
        course_id: data[:course].id,
        user_id: data[:user].id,
        student_id: data[:student].id,
        user_role: "student",
        last_login_at: Integer,
        event_type: :login,
        created_at: Time
      }

      expect(Analytics::LoginEvent).to receive(:create).with(event_data)
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
