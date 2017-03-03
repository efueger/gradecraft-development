module GoogleCalendarHelper

  Calendar = Google::Apis::CalendarV3

  def get_google_authorization(current_user)
    current_user.authorizations.find_by(provider: "google_oauth2")
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
    secrets = Google::APIClient::ClientSecrets.new({"web" =>
      {"access_token" => google_authorization.access_token,
        "refresh_token" => google_authorization.refresh_token,
        "client_id" => ENV['GOOGLE_CLIENT_ID'],
        "client_secret" => ENV['GOOGLE_SECRET']}
        })
    secrets
  end
end
