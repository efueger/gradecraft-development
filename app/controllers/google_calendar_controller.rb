class GoogleCalendarController < ApplicationController
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
    @google_authorization = current_user.authorizations.find_by(provider: "google_oauth2")
    if !@google_authorization.nil?
      @google_authorization = current_user.authorizations.find_by(provider: "google_oauth2")
      if Time.now > @google_authorization.expires_at
        @google_authorization.refresh!({ client_id: ENV["GOOGLE_CLIENT_ID"], client_secret: ENV["GOOGLE_SECRET"] })
      end
      @event = current_course.events.find(params[:id])

      if !@event.open_at.nil? && !@event.due_at.nil?
        event = Calendar::Event.new({
          summary: @event.name,
          start: {
            date_time: @event.open_at.to_datetime.rfc3339
          },
          end: {
            date_time: @event.due_at.to_datetime.rfc3339
          }
        })

        calendar = Calendar::CalendarService.new
        client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_SECRET'])

        secrets = Google::APIClient::ClientSecrets.new({"web" =>
          {"access_token" => @google_authorization.access_token,
            "refresh_token" => @google_authorization.refresh_token,
            "client_id" => ENV['GOOGLE_CLIENT_ID'],
            "client_secret" => ENV['GOOGLE_SECRET']}
          })
        calendar.authorization = secrets.to_authorization
        calendar.authorization.refresh!

        event = calendar.insert_event('primary', event)
      else
        puts "event missing START or END time"
      end

      redirect_to "/events"
    else
      puts "google_oath2 does not exist. Redirecting to authentication page"
      redirect_to "/auth/google_oauth2"
    end
  end

end
