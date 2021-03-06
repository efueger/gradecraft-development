Rails.application.configure do
  config.action_controller.default_url_options = { :host => "beta.gradecraft.com" }
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
  config.action_dispatch.default_headers = { "X-Frame-Options" => "ALLOWALL" }
  config.asset_host = "https://beta.gradecraft.com"
  config.action_mailer.default_url_options = { :host => "beta.gradecraft.com" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.delivery_method = :sparkpost
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_cable.mount_path = nil
  config.action_cable.url = 'wss://beta.gradecraft.com/cable'
  config.action_cable.allowed_request_origins = [ 'http://beta.gradecraft.com',
                                                  /http:\/\/beta.gradecraft.*/ ]
  config.active_support.deprecation = :notify
  config.assets.compile = false
  config.assets.compress = true
  config.assets.css_compressor = :sass
  config.assets.digest = true
  config.assets.js_compressor = Uglifier.new(mangle: false) if defined? Uglifier
  config.cache_classes = true
  config.cache_store = :dalli_store, ENV["MEMCACHED_URL"], { :namespace => "gradecraft_beta", :expires_in => 1.day, :compress => true }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :debug
  config.log_tags = [:request_id]
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.session_store :active_record_store, :expire_after => 60.minutes
end

CarrierWave.configure do |config|
  config.storage = :fog
end
