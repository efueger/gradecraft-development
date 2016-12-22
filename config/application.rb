require_relative 'boot'

require 'rails/all'
require "csv"
require "sanitize"

Bundler.require(*Rails.groups)

module GradeCraft
  class Application < Rails::Application
    config.time_zone = "America/Detroit"
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/models/abilities)

    config.assets.precompile += %w(.svg .eot .otf .woff .ttf)
    config.filter_parameters += [:password]

    config.active_job.queue_adapter = :resque

    config.i18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.angular_templates.ignore_prefix  = %w(angular/templates/)
    config.generators do |g|
      g.orm :active_record
      g.stylesheets :false
      g.template_engine :haml
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end
  end
end
