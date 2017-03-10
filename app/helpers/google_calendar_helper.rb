require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets.rb'
require 'googleauth'

module GoogleCalendarHelper
  Calendar = Google::Apis::CalendarV3

  def get_google_authorization(current_user)
    google_authorization = current_user.authorizations.find_by(provider: "google_oauth2")
    reroute_to_google_login_if_unauthenticated(google_authorization)
    refresh_if_google_authorization_is_expired(google_authorization)
    google_authorization
  end

  def reroute_to_google_login_if_unauthenticated(google_authorization)
    return unless google_authorization.nil?
    redirect_to "/auth/google_oauth2"
  end

  def refresh_if_google_authorization_is_expired(google_authorization)
    return unless google_authorization.expired?
    google_authorization.refresh!({ client_id: ENV["GOOGLE_CLIENT_ID"], client_secret: ENV["GOOGLE_SECRET"] })
  end

  def create_google_event(event)
    google_event = Calendar::Event.new({
      summary: event.name,
      start: {
        date_time: event.open_at.to_datetime.rfc3339
      },
      end: {
        date_time: event.due_at.to_datetime.rfc3339
      }
    })
    google_event
  end

  def create_google_secrets(google_authorization)
    Google::APIClient::ClientSecrets.new({"web" =>
      {"access_token" => google_authorization.access_token,
        "refresh_token" => google_authorization.refresh_token,
        "client_id" => ENV['GOOGLE_CLIENT_ID'],
        "client_secret" => ENV['GOOGLE_SECRET']}
        })
  end
end
