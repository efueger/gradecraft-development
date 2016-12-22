class RecordLoginEventJob < ApplicationJob
  queue_as :login_event_logger

  attr_reader :logged_data

  before_perform do |job|
    data = job.arguments.first
    logger = job.arguments.second

    logger.info "Starting LoginEventLogger with data #{data}"
  end

  after_perform do |job|
    logger = job.arguments.second
    logger.info "Successfully logged login event data #{job.logged_data}"
  end

  def perform(data={}, logger=NilLogger.new)
    course_membership = CourseMembership.find_by user_id: data[:user_id],
      course_id: data[:course_id]

    @logged_data = data.merge(last_login_at: course_membership.last_login_at.try(:to_i))
    result = Analytics::LoginEvent.create logged_data

    course_membership.update_attributes last_login_at: data[:created_at]
  end
end
