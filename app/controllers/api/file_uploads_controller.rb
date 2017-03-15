class API::FileUploadsController < ApplicationController

  before_action :ensure_staff?

  # POST /api/grades/:grade_id/attachments
  def create
    grade = Grade.find(params[:grade_id])

    @file_uploads = []
    params[:file_uploads].each do |f|
      file = grade.file_uploads.create(
        file: f,
        filename: f.original_filename[0..49],
        # course and assignment are used to maintain directory structure
        course: grade.course,
        assignment: grade.assignment)
      @file_uploads << file
    end
    render "api/file_uploads/index", status: 201
  end

  # POST /api/assignments/:assignment_id/groups/:group_id/attachments
  def group_create
    group = Group.find(params[:group_id])
    assignment = Assignment.find(params[:assignment_id])

    @file_uploads = []
    params[:file_uploads].each do |f|
      file = FileUpload.create(
        file: f,
        filename: f.original_filename[0..49],
        # course and assignment are used to maintain directory structure
        course: assignment.course,
        assignment: assignment)
      @file_uploads << file
    end
    group.students.each do |student|
      student.grade_for_assignment(assignment).file_uploads << @file_uploads
    end
    render "api/file_uploads/index", status: 201
  end

  # DELETE /api/file_uploads/:id
  def destroy
    file = FileUpload.where(id: params[:id]).first
    if file.present?
      file.delete_from_s3
      file.destroy

      Attachment.where(file_upload_id: file.id).destroy_all

      if !file.exists_on_s3? && file.destroyed?
        render json: { message: "Grade file successfully deleted", success: true },
        status: 200
      elsif file.destroyed?
        render json: {message: "Grade file deleted, error removing remote file", success: true},
        status: 200
      else
        render json: {message: "Grade file failed to delete", success: false},
        status: 400
      end
    else
      render json: {message: "Grade file not found", success: false},
      status: 400
    end
  end
end
