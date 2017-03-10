class AddCourseAssignmentToFileUpload < ActiveRecord::Migration[5.0]
  def change
    add_column :file_uploads, :course_id, :integer
    add_column :file_uploads, :assignment_id, :integer
  end
end
