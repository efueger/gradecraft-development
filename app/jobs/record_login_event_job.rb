class RecordLoginEventJob < ApplicationJob
  queue_as :login_event_logger

  def perform(data={}, logger=NilLogger.new)
    logger.info "Starting LoginEventLogger with data #{data}"

    course_membership = CourseMembership.find_by user_id: data[:user_id],
      course_id: data[:course_id]

    log_data = data.merge(last_login_at: course_membership.last_login_at.try(:to_i))
    result = Analytics::LoginEvent.create log_data

    course_membership.update_attributes last_login_at: data[:created_at]

    logger.info "Successfully logged login event data #{log_data}"
  end
end
