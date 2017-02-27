class GoogleCalendarController < ApplicationController
  include OAuthProvider

  oauth_provider_param :google_oauth2

  def index
    binding.pry
    puts "stopped"
    redirect_to "/events"
  end

  def refresh_google_token
    @google_authorization = current_user.authorizations.find_by(provider: "google_oauth2")
    if !@google_authorization.nil?
        puts "google_oauth2 exists"
        @google_authorization = current_user.authorizations.find_by(provider: "google_oauth2")
        puts "expires_at:    " + @google_authorization.expires_at.to_s
        if Time.now > @google_authorization.expires_at
          puts "google_oauth2 exists but is expired. Refreshing token."
          @google_authorization.refresh!({ client_id: ENV["GOOGLE_CLIENT_ID"], client_secret: ENV["GOOGLE_SECRET"] })
          puts "token is now refreshed"
        else
          puts "Token is fine"
        end
        #get event info
        puts "name: " + params[:id]
        @event = current_course.events.find(params[:id])
        puts "event: " + @event.open_at.to_s

        @client = Google::APIClient.new
        @client.authorization.access_token = @google_authorization.access_token
        @client.authorization.refresh_token = @google_authorization.refresh_token
        @client.authorization.client_id = ENV["GOOGLE_CLIENT_ID"]
        @client.authorization.client_secret = ENV["GOOGLE_SECRET"]
        @client.authorization.refresh!

        @service = @client.discovered_api('calendar', 'v3')

        event = {
          summary: "New Event!",
          start: {dateTime: '2017-02-27T09:00:00+0000'},
          end:   {dateTime: '2017-02-27T10:00:00+0000'}
        }

        @client.execute(:api_method => @service.events.insert,:parameters =>
        {'calendarId' => 'primary','sendNotifications' => false},
        :body => JSON.dump(event),:headers => {'Content-Type' => 'application/json'})

        redirect_to "/events"
    else
      puts "google_oath2 does not exist. Redirecting to authentication page"
      redirect_to "/auth/google_oauth2"
    end

  end

end
