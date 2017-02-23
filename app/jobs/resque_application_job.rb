class ResqueApplicationJob < ApplicationJob
  extend Resque::Plugins::Retry
  extend Resque::Plugins::ExponentialBackoff

  def self.backoff_strategy
    @backoff_strategy ||= ResqueJob.configuration.backoff_strategy
  end
end
