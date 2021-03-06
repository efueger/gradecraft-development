require "quote_helper"

class CanvasGradeImporter
  attr_reader :successful, :unsuccessful
  attr_accessor :grades

  def initialize(grades)
    @grades = grades
    @successful = []
    @unsuccessful = []
  end

  def import(assignment_id, syllabus, override=false)
    unless grades.nil?
      grades.each do |canvas_grade|
        user = find_user canvas_grade["user_id"], syllabus

        if override
          grade = Grade.find_or_initialize_by student_id: user.try(:id),
            assignment_id: assignment_id
        else
          grade = Grade.new student_id: user.try(:id), assignment_id: assignment_id
        end

        grade.raw_points = canvas_grade["score"]
        grade.feedback = canvas_grade["submission_comments"]
        grade.status = "Graded" if grade.status.nil?
        grade.instructor_modified = true

        if grade.save
          link_imported canvas_grade["id"], grade
          successful << grade
        else
          unsuccessful << { data: canvas_grade,
                            errors: grade.errors.full_messages.join(", ") }
        end
      end
    end

    self
  end

  private

  def find_user(user_id, syllabus)
    canvas_user = syllabus.user(user_id)
    return nil if canvas_user.nil?

    User.find_by_insensitive_email(canvas_user["primary_email"])
  end

  def link_imported(provider_resource_id, grade)
    imported = ImportedGrade.find_or_initialize_by(provider: :canvas,
      provider_resource_id: provider_resource_id)
    imported.grade = grade
    imported.save
  end
end
