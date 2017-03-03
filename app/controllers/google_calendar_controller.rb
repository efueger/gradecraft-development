class GoogleCalendarController < ApplicationController
  include GoogleCalendarHelper
  include OAuthProvider

  oauth_provider_param :google_oauth2
  require 'google/apis/calendar_v3'
  require 'google/api_client/client_secrets.rb'
  require 'googleauth'

  Calendar = Google::Apis::CalendarV3

  def index
    redirect_to "/events"
  end

  def add_event_to_google_calendar
    google_authorization = get_google_authorization(current_user)
    if google_authorization.nil?
      redirect_to "/auth/google_oauth2"
    end
    if Time.now > google_authorization.expires_at
      google_authorization.refresh!({ client_id: ENV["GOOGLE_CLIENT_ID"], client_secret: ENV["GOOGLE_SECRET"] })
    end
    event = current_course.events.find(params[:id])
    if event.open_at.nil? || event.due_at.nil?
      redirect_to "/events", alert: "Google Calendar requires event have both START and END time!"
    else
      begin
        google_event = create_google_event(event)
        calendar = Calendar::CalendarService.new
        client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_SECRET'])
        secrets = create_google_secrets(google_authorization)
        calendar.authorization = secrets.to_authorization
        calendar.authorization.refresh!
        result = calendar.insert_event('primary', google_event)
        redirect_to "/events", notice: "Event " + event.name + " successfully added to your Google Calendar"
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError
        redirect_to "/events", alert: "Google Calendar encountered an Error. Your event was NOT copied to your Google calendar."
      end
    end
  end
end
