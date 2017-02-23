class ResqueApplicationJob < ApplicationJob
  extend Resque::Plugins::Retry
end
