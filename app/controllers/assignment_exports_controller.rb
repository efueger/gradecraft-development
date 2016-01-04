class AssignmentExportsController < ApplicationController
  before_filter :ensure_staff?

  def create
    create_assignment_export_job
    @assignment_export_job.enqueue ? job_success_outcome : job_failure_outcome
    redirect_to assignment_path(assignment)
  end

  protected

  def create_assignment_export_job
    @assignment_export_job = AssignmentExportJob.new({
      assignment_id: params[:assignment_id],
      professor_id: current_user.id,
      course_id: current_course.id,
      team_id: params[:team_id]
    })
  end

  def job_success_outcome
    flash[:success] = "Your assignment export is being prepared. You'll receive an email when it's complete."
  end

  def job_failure_outcome
    flash[:alert] = "Your assignment export failed to build. An administrator has been contacted about the issue."
  end

  def assignment
    @assignment ||= Assignment.find(params[:assignment_id])
  end
end
