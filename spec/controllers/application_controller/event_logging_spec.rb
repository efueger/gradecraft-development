require "rails_spec_helper"
require "resque-scheduler"
require "resque_spec/scheduler"

# define routes for mapping #html_page and #json_page to the test controller
include Toolkits::Controllers::ApplicationControllerToolkit::Routes

RSpec.describe ApplicationController do

  # let's run the tests on a subclass of ApplicationController that has mock
  # actions built out so that we can just test filters
  describe ApplicationControllerTest do
    subject { get :html_page }

    let(:course) { build(:course) }
    let(:user) { create(:user) }
    let(:student) { create(:user) }

    let(:event_session) {{
      course: course,
      user: user,
      student: student,
      request: request
    }}

    before do
      allow(user).to receive_messages(current_course: course, require_course_membership: true)
      define_test_routes # define dummy :html_page and :json_page routes
      allow(controller).to \
        receive_messages(current_user: user, event_session: event_session, require_course_membership: true)
    end

    describe "triggering pageview logger events" do
      let(:logger_class) { PageviewEventLogger }

      context "no user is logged in" do
        it "should not call PageviewEventLogger" do
          allow(controller).to receive_messages(current_user: nil)
          expect(logger_class).not_to receive(:new).with event_session
          subject
        end
      end

      context "a user is logged in and the request is for html" do
        let(:event_logger) { logger_class.new }
        let(:enqueue_response) { double(:enqueue_response) }

        before(:each) do
          allow(Lull).to receive_messages(time_until_next_lull: 2.hours)
          allow(event_logger).to receive_messages(enqueue_in: enqueue_response)
          allow(logger_class).to receive_messages(new: event_logger)
        end

        it "should create a new PageviewEventLogger" do
          expect(logger_class).to receive(:new).with(event_session)
            .and_return event_logger
          subject
        end

        it "should enqueue the new pageview event in 2 hours" do
          expect(event_logger).to receive(:enqueue_in_with_fallback)
            .with(2.hours) { enqueue_response }
          subject
        end
      end

      context "the request is not html" do
        it "should not call #{described_class}" do
          expect(PageviewEventLogger).not_to receive(:new).with event_session
          get :json_page, format: "json"
        end
      end
    end

    describe "#record_course_login_event" do
      let(:result) { controller.record_course_login_event }
      let(:logger_class) { EventLoggers::LoginEvent }

      before do
        create :course_membership, :professor, course: course, user: user
      end

      context "the request is not html or xml" do
        let(:format) {{ html?: false, xml?: false, json?: true }}

        it "should not build a LoginEventLogger" do
          allow(controller.request.format).to receive_messages(format)
          expect(logger_class).not_to receive(:new)
          result
        end
      end

      context "request has a valid format" do
        let(:event_logger) { logger_class.new }
        let(:enqueue_response) { double(:enqueue_response).as_null_object }

        before do
          allow(logger_class).to receive_messages(new: event_logger)
          allow(event_logger).to receive_messages(log_later: enqueue_response)
        end

        context "no login_course is expressly given" do
          it "should creates a new login event with the event session data" do
            expect(event_logger).to \
              receive(:log_later).with(event_session.merge(request: nil))
            result
          end
        end

        context "custom event_options are given" do
          it "merges the event_options into the event_session" do
            expect(event_logger).to receive(:log_later)
              .with event_session.merge(request: nil, mock_attr: "some-value")
            controller.record_course_login_event mock_attr: "some-value"
          end
        end

        it "should enqueue the new login event" do
          expect(event_logger).to receive(:log_later)
            .and_return enqueue_response
          result
        end
      end
    end

    describe "#event_session" do
      let(:request) { double(:some_request) }
      before do
        allow(controller).to receive_messages(
          current_course: course,
          current_user: user,
          current_student: student,
          request: request
        )
      end

      it "returns a hash with current course, user, student and request" do
        expect(controller.event_session).to eq(event_session)
      end
    end

    after do
      # reload the proper routes to clear out custom /html_page
      # and /json_page routes
      Rails.application.reload_routes!
    end
  end
end
