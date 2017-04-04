source 'https://rubygems.org'

#ruby '2.2.2'

gem 'rails'
gem 'resque', '1.26'
gem 'activerecord-import'
gem 'active_model_serializers'
gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'addressable'
gem 'angularjs-rails', '~> 1.4.2'
gem 'angular-rails-templates'

# zip utility for simple creation of zip files, pure ruby implementation
# without the GC overhead of the Rubyzip library
gem 'archive-zip', '~> 0.7.0'

gem 'autonumeric-rails'
gem 'autoprefixer-rails'
gem 'aws-sdk', '~> 2'
gem 's3_direct_upload'
gem 'cancancan'
gem 'carrierwave', '~> 0.10.0'
gem 'carrierwave_backgrounder', '0.4.2'
gem 'coffee-rails'
gem 'croutons'
gem 'd3-rails'
gem 'dalli'

# adds expect{something}.to 'make_database_queries' matchers to rspec
# useful for testing eager/lazy loading
gem 'db-query-matchers'

gem 'dotenv-rails'

gem 'fast_blank'
gem 'fog'
gem 'font-awesome-rails', '~> 4.7'
gem 'haml'
gem 'httparty'
gem 'ims-lti', '~> 1.1.13'
gem 'jbuilder'
gem 'jquery-rails'

gem 'light-service'

# interface for connecting to remote logging system Loggly
gem 'logglier', '~> 0.3.0'

gem 'multi_json'
gem 'mini_magick'
gem 'mongoid', '~> 6.0.0'
gem 'ng-rails-csrf'
gem 'nokogiri'
gem 'oauth', '~> 0.5'
gem 'oink'
gem 'oj'
gem 'omniauth', '~> 1.3.1'
gem 'omniauth-canvas'
gem 'omniauth-kerberos'
gem 'omniauth-lti', '~> 0.0.2'

gem 'pacecar'
gem 'paper_trail'
gem 'pg'
gem 'puma'
gem 'rack-mini-profiler', require: false
gem 'rails_autolink'
gem 'rdiscount'
gem 'record_tag_helper'

# retry dsl for resque
gem 'resque-retry'

# handles deferrence of Resque jobs to a later time
# ex: Resque.enqueue_in(5.hours, @worker_object)
gem 'resque-scheduler', require: 'resque/scheduler'

# slightly more mature rate limiter plugin for resque
# gem 'resque-waiting-room'

# limits the number of jobs that are run per unit of time on a given queue
# ex: Resque.rate_limit(:my_queue, :at => 10, :per => 60)
gem 'resque-throttler', require: 'resque/throttler'

gem 'responders'
gem 'rollbar'
gem 'sampler'
gem 'sanitize'
gem 'sassc-rails'

# secure crypt hashing library stronger than bcrypt or PBDBF2
gem 'scrypt', '2.0.2'

gem 'select2-rails'
gem 'simple_form'
gem 'sorcery'
gem 'sparkpost_rails'
gem 'uglifier'
gem 'underscore-rails'
gem 'whenever'
gem 'newrelic_rpm'
gem 'wysiwyg-rails'
gem 'ruby-saml', '~> 1.4.1'

group :development do
  gem 'haml-rails'
  gem 'valid_attribute'
  gem 'foreman'
  gem 'rubystats'
end

group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'jasmine-rails'
end

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner', '~> 1.5.1'
  gem 'faker'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'capybara-select2'
  gem 'launchy'
  gem 'rails-controller-testing', require: false
  gem 'rspec-rails', '~> 3.5.2'
  # add spec helpers for testing Resque objects and resque scheduler
  gem 'resque_spec', git: 'https://github.com/leshill/resque_spec.git', branch: 'master'
  gem 'rspec-html-matchers'
  gem 'simplecov'
  gem 'webmock'
end

group :tasks do
  gem 'rake-hooks'
end

source 'https://rails-assets.org' do
  gem 'rails-assets-angular', '1.3.15'
  gem 'rails-assets-angular-resource', '1.3.15'
  gem 'rails-assets-lodash', '3.7.0'
  gem 'rails-assets-jquery', '2.1.4'
  gem 'rails-assets-angular-dragdrop', '1.0.11'
  gem 'rails-assets-ngDraggable', '0.1.8'
end
