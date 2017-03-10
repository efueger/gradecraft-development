namespace :attachments do

  desc "Add grade file association for many to many relationship"
  task add_associations: :environment do
    FileUpload.find_each(batch_size: 500) do |fu|
      if Attachment.where(file_upload_id: fu.id, grade_id: fu.grade_id).empty?
        Attachment.create(file_upload_id: fu.id, grade_id: fu.grade_id)
      end
      fu.update_attributes course_id: fu.grade.course_id, assignment_id: fu.grade.assignment_id
    end
  end
end
