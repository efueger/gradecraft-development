class API::Grades::AttachmentsController < ApplicationController

  before_action :ensure_staff?

  # POST /api/grades/:grade_id/attachments
  def create
    grade = Grade.find(params[:grade_id])

    @file_uploads = []
    params[:file_uploads].each do |f|
      file = FileUpload.create(
        file: f, filename: f.original_filename[0..49],
        grade_id: grade.id,
        course_id: grade.course.id,
        assignment_id: grade.assignment.id
      )
      Attachment.create(file_upload_id: file.id, grade_id: grade.id)
      @file_uploads << file
    end

    render status: 201
  end

  # DELETE /api/grades/:grade_id/attachments/:id
  def destroy
    file = FileUpload.where(id: params[:id], grade_id: params[:grade_id]).first
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
