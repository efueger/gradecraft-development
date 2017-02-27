require "omniauth-canvas"
require "omniauth-google-oauth2"

class UserAuthorization < ActiveRecord::Base
  belongs_to :user

  def self.create_by_auth_hash(auth_hash, user)
    provider = auth_hash["provider"]
    attributes = { access_token:  auth_hash["credentials"]["token"],
                   refresh_token: auth_hash["credentials"]["refresh_token"],
                   expires_at:    Time.at(auth_hash["credentials"]["expires_at"]) }

    authorization = self.find_or_initialize_by provider: provider, user_id: user.id
    authorization.update_attributes attributes
    authorization
  end

  def expired?
    self.expires_at < DateTime.now
  end

  def self.for(user, provider)
    where(user_id: user.id, provider: provider).first
  end

  def refresh!(options={})
    return false if self.refresh_token.blank?

    strategy = provider_class.new nil, options
    token = refreshed_token(strategy)

    self.update_attributes \
      access_token: token.token,
      refresh_token: token.refresh_token,
      expires_at: (DateTime.now + token.expires_in.to_i.seconds)
  end

  def refresh_with_config!(config)
    self.refresh!({ client_id: config.client_id,
                    client_secret: config.client_secret,
                    client_options: config.client_options })
  end

  private

  def provider_class
    OmniAuth::Strategies.const_get self.provider.to_s.camelize
  end

  def refreshed_token(strategy)
    token = OAuth2::AccessToken.new strategy.client,
      self.access_token, { refresh_token: self.refresh_token }
    token.refresh!
  end
end
