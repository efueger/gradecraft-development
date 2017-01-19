#TODO: Move this to it's own file in a system that supports the AJ background jobs
class JobFailedError < RuntimeError
  attr_reader :job

  def initialize(message, job)
    @job = job
    super message
  end
end

class RecordLoginEventJob < ApplicationJob
  queue_as :login_event_logger

  attr_reader :logged_data

  def data
    self.arguments.first
  end

  def logger
    self.arguments.second || NullLogger.new
  end

  before_perform do |job|
    job.logger.info "Starting LoginEventLogger with data #{data}"
  end

  after_perform do |job|
    job.logger.info "Successfully logged login event with data #{job.logged_data}"
  end

  rescue_from JobFailedError do |exception|
    exception.job.logger.info "Failed to log login event with data #{exception.job.data}"
  end

  def perform(data={}, logger=NullLogger.new)
    raise JobFailedError.new("User role not specfied", self) if data[:user_role].blank?

    course_membership = CourseMembership.find_by user_id: data[:user_id],
      course_id: data[:course_id]

    last_login_at = course_membership.try(:last_login_at).try(:to_i)
    @logged_data = data.merge(last_login_at: last_login_at)
    result = Analytics::LoginEvent.create logged_data
    raise JobFailedError.new("Event was not logged", self) unless result.valid?

    unless course_membership.nil?
      course_membership.update_attributes last_login_at: data[:created_at]
    end
  end
end
