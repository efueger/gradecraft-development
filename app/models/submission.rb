class Submission < ActiveRecord::Base
  include Historical
  include MultipleFileAttributes
  include Sanitizable

  has_paper_trail ignore: [:text_comment_draft]

  belongs_to :assignment
  belongs_to :student, class_name: "User"
  belongs_to :creator, class_name: "User"
  belongs_to :group
  belongs_to :course, touch: true

  after_save :check_unlockables

  has_one :grade
  has_one :assignment_type_weight, through: :assignment_type

  accepts_nested_attributes_for :grade
  has_many :submission_files,
    dependent: :destroy,
    autosave: true,
    inverse_of: :submission
  accepts_nested_attributes_for :submission_files

  scope :with_grade, -> do
    joins("INNER JOIN grades ON "\
      "grades.assignment_id = submissions.assignment_id AND "\
      "(grades.group_id = submissions.group_id OR "\
      "grades.student_id = submissions.student_id)")
  end

  scope :ungraded, -> do
    includes(:assignment, :group, :student)
    .where.not(id: with_grade.where(grades: { status: ["In Progress", "Graded", "Released"] }))
  end

  scope :resubmitted, -> {
    includes(:grade, :assignment)
    .where("grades.status = 'Released' OR (grades.status = 'Graded' AND NOT assignments.release_necessary)")
    .where("grades.graded_at < submitted_at")
    .references(:grade, :assignment)
  }
  scope :order_by_submitted, -> { order("submitted_at ASC") }
  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }
  scope :for_assignment_and_student, ->(assignment_id, student_id) { where(assignment_id: assignment_id, student_id: student_id) }
  scope :for_assignment_and_group, ->(assignment_id, group_id) { where(assignment_id: assignment_id, group_id: group_id) }
  scope :submitted, -> { where.not(submitted_at: nil) }
  scope :with_group, -> { where "group_id is not null" }

  before_validation :cache_associations

  validate :student_xor_group
  validates :link, format: URI::regexp(%w(http https)), allow_blank: true
  validates_length_of :link, maximum: 255
  validates :assignment, presence: true, uniqueness: { scope: [:student, :group],
    message: "should only have one submission per student or group" }, allow_nil: true
  validates_with SubmissionValidator

  clean_html :text_comment
  multiple_files :submission_files

  def self.submitted_this_week(assignment_type)
    assignment_type.submissions.submitted.where("submissions.submitted_at > ? ", 7.days.ago)
  end

  def graded_at
    submission_grade.graded_at if graded?
  end

  def graded?
    !ungraded?
  end

  def submission_grade
    return nil if student.nil?
    student.grades.where(assignment_id: self.assignment_id).first
  end

  # Grabbing any submission that has NO instructor-defined grade
  def ungraded?
    !submission_grade || submission_grade.status.nil?
  end

  # Reports to the user that a change will be a resubmission because this
  # submission is already graded and visible to them.
  def will_be_resubmitted?
    return false unless submission_grade.present? && submission_grade.student_visible?
    return true
  end

  # this is transitive so that once it is graded again, then
  # it will no longer be resubmitted
  def resubmitted?
    graded? && !graded_at.nil? && !submitted_at.nil? && graded_at < submitted_at
  end

  # Getting the name of the student who submitted the work
  def name
    student.name
  end

  def submitter
    assignment.has_groups? ? group : student
  end

  def submitter_id
    assignment.has_groups? ? group_id : student_id
  end

  # Checking to see if a submission was turned in late
  # Set while skipping validations and callbacks
  def check_and_set_late_status!
    return false if self.assignment.due_at.nil?
    self.update_column(:late, submitted_at > self.assignment.due_at)
  end

  # build a sensible base filename for all files that are attached to this submission
  def base_filename
    owner = student || group
    [owner.name, assignment.name].collect do |part|
      Formatter::Filename.titleize part
    end.compact.join " - "
  end

  def has_multiple_components?
    count = 0
    count += submission_files.count
    if link.present?
      count += 1
    end
    if text_comment.present?
      count +=1
    end
    return true if count > 1
    false
  end

  def check_unlockables
    if self.assignment.is_a_condition?
      unlock_conditions = UnlockCondition.where(condition_id: self.assignment.id, condition_type: "Assignment").each do |condition|
        unlockable = condition.unlockable
        if self.assignment.has_groups?
          self.group.students.each do |student|
            unlockable.unlock!(student)
          end
        else
          unlockable.unlock!(student)
        end
      end
    end
  end

  def process_unconfirmed_files
    submission_files.unconfirmed.each do |submission_file|
      submission_file.check_and_set_confirmed_status
    end
  end

  def confirm_all_files
    submission_files.each do |submission_file|
      submission_file.check_and_set_confirmed_status
    end
  end

  def unsubmitted?
    submitted_at.nil?
  end

  def belongs_to?(user)
    if assignment.is_individual?
      student_id == user.id
    else
      user.group_memberships.pluck(:group_id).include? group_id
    end
  end

  private

  def cache_associations
    self.assignment_id ||= assignment.id
    self.course_id ||= assignment.course_id
  end

  def student_xor_group
    errors.add(:base, "must have either a student_id or group_id, but not both") unless student.nil? ^ group.nil?
  end
end
