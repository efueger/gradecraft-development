require "csv"
require "quote_helper"

class CSVGradeImporter
  include GradesHelper
  attr_reader :successful, :unsuccessful, :unchanged
  attr_accessor :file

  PASS_FAIL_GRADE_VALUES ||= [0,1].freeze

  def initialize(file)
    @file = file
    @successful = []
    @unsuccessful = []
    @unchanged = []
  end

  def import(course=nil, assignment=nil)
    if file
      if course && assignment
        students = course.students
        CSV.foreach(file, headers: true) do |csv|
          row = GradeRow.new csv

          student = find_student(row, students)
          if student.nil?
            append_unsuccessful row, "Student not found in course"
            next
          end
          if !row.has_grade?
            append_unsuccessful row, "Grade not specified"
            next
          end
          if !is_valid_grade? assignment, row.grade
            append_unsuccessful row, "Grade is invalid"
            next
          end

          grade = assignment.grades.where(student_id: student.id).first
          if update_grade? row, grade, assignment
            grade = update_grade row, grade
            report row, grade
          elsif grade.present?
            unchanged << grade
          elsif grade.nil?
            grade = create_grade row, assignment, student
            report row, grade
          end
        end
      end
    end

    self
  end

  private

  def append_unsuccessful(row, errors)
    unsuccessful << { data: row.to_s, errors: errors }
  end

  def assign_grade(row, grade)
    grade.feedback = row.feedback
    grade.status = "Graded" if grade.status.nil?
    grade.instructor_modified = true
    grade.graded_at = DateTime.now
    set_grade_score row, grade
  end

  def create_grade(row, assignment, student)
    assignment.grades.create do |grade|
      grade.student_id = student.id
      assign_grade row, grade
    end
  end

  def update_grade(row, grade)
    assign_grade row, grade
    grade.save
    grade
  end

  def find_student(row, students)
    message = row.identifier =~ /@/ ? :email : :username
    students.find do |student|
      student.public_send(message).downcase == row.identifier
    end
  end

  def report(row, grade)
    if grade.valid?
      successful << grade
    else
      append_unsuccessful row, grade.errors.full_messages.join(", ")
    end
  end

  # Precondition: row.grade has been validated by is_valid_grade?
  def set_grade_score(row, grade)
    score = Integer(row.grade)
    if grade.assignment.pass_fail?
      grade.pass_fail_status = pass_fail_status_for score
    else
      grade.raw_points = score
    end
  end

  # Ensures that the input is valid and integer-like
  def is_valid_grade?(assignment, grade)
    begin
      return false if grade.nil?
      # Integer() vs to_i to prevent unwanted coercion
      return PASS_FAIL_GRADE_VALUES.include?(Integer(grade)) if assignment.pass_fail?
      true
    rescue ArgumentError
      false
    end
  end

  # If the assignment is pass/fail type, update the grade if the status or feedback changes
  # Else, update if the raw points or feedback changes
  # Precondition: row.grade has been validated by is_valid_grade?
  def update_grade?(row, grade, assignment)
    score = Integer(row.grade)
    if assignment.pass_fail?
      grade.present? && (grade.pass_fail_status != pass_fail_status_for(score) || grade.feedback != row.feedback)
    else
      grade.present? && (grade.raw_points != score || grade.feedback != row.feedback)
    end
  end

  class GradeRow
    include QuoteHelper
    attr_reader :data

    def identifier
      remove_smart_quotes(data[2]).downcase if data[2].present?
    end

    def feedback
      remove_smart_quotes data[4]
    end

    def grade
      remove_smart_quotes data[3]
    end

    def has_grade?
      grade.present?
    end

    def initialize(data)
      @data = data
    end

    def to_s
      data.to_s
    end
  end
end
