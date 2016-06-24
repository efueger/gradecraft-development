class AssignmentType < ActiveRecord::Base
  include Copyable

  acts_as_list scope: :course

  attr_accessible :max_points, :name, :description, :student_weightable,
    :position, :top_grades_counted

  belongs_to :course, touch: true
  has_many :assignments, -> { order("position ASC") }, dependent: :destroy
  has_many :submissions, through: :assignments
  has_many :grades

  # This is the assignment weighting system (students decide how much
  # assignments will be worth for them)
  has_many :weights, class_name: "AssignmentTypeWeight", dependent: :destroy

  validates_presence_of :name, :max_points
  validate :positive_max_points

  scope :student_weightable, -> { where(student_weightable: true) }

  default_scope { order "position" }

  def copy(attributes={})
    ModelCopier.new(self).copy(attributes: attributes, associations: [:assignments])
  end

  # weights default to 1 if not weightable, and
  # 0 if weightable but not weighted by the student
  def weight_for_student(student)
    return 1 unless student_weightable?
    weights.where(student: student).first.try(:weight) || course.default_weight
  end

  def is_capped?
    max_points > 0
  end

  # Checking to see if the instructor has set a maximum number of grades that
  # should count towards the assignment type score - always the highest ones
  def count_only_top_grades?
    top_grades_counted > 0
  end

  # Getting the assignment types max value if it's present, else returning the
  # summed total of assignment points
  def total_points
    if max_points > 0
      max_points
    else
      summed_assignment_points
    end
  end

  # Calculating the total number of assignment points in the type
  def summed_assignment_points
    assignments.map{ |a| a.full_points || 0 }.sum
  end

  def total_points_for_student(student)
    if max_points > 0
      max_points
    else
      if student_weightable?
        weighted_total_for_student(student)
      else
        summed_assignment_points
      end
    end
  end

  def weighted_total_for_student(student)
    if weight_for_student(student) >= 1
      (total_points * weight_for_student(student)).to_i
    else
      (total_points * course.default_weight).to_i
    end
  end

  def visible_score_for_student(student)
    if count_only_top_grades?
      return summed_highest_scores_for(student)
    elsif is_capped?
      return max_points_for_student(student)
    else
      return score_for_student(student)
    end
  end

  def grades_for(student)
    student.grades.student_visible
                  .not_nil
                  .included_in_course_score
                  .where(assignment_type: self)
  end

  def score_for_student(student)
    grades_for(student).pluck("score").sum || 0
  end

  def raw_points_for_student(student)
    grades_for(student).pluck("raw_points").sum || 0
  end

  def final_points_for_student(student)
    grades_for(student).pluck("final_points").sum || 0
  end

  # Calculating what the total highest points for the type is for a student
  def summed_highest_scores_for(student)
    if self.count_only_top_grades?
      score = grades_for(student)
                    .order_by_highest_score
                    .first(top_grades_counted).sum(&:score) || 0
      return max_points if (max_points > 0) && (score > max_points)
      score
    end
  end

  def max_points_for_student(student)
    score = score_for_student(student)
    return max_points if score > max_points
    score
  end

  private

  def positive_max_points
    if max_points < 0
      errors.add :base, "Maximum points must be a positive number."
    end
  end
end
