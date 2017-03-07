class Group < ActiveRecord::Base
  include ActiveModel::Validations
  include Sanitizable

  APPROVED_STATUSES = ["Pending", "Approved", "Rejected"]

  attr_reader :student_tokens

  belongs_to :course

  has_many :assignment_groups, dependent: :destroy, inverse_of: :group
  has_many :assignments, through: :assignment_groups
  accepts_nested_attributes_for :assignment_groups

  has_many :group_memberships, dependent: :destroy
  has_many :students, through: :group_memberships
  accepts_nested_attributes_for :group_memberships

  has_many :grades

  has_many :submissions
  has_many :submissions_exports

  has_many :earned_badges, as: :group

  before_validation :cache_associations

  validates_presence_of :name, :approved

  validates :group_size, group_size: true
  validates_with UniqueAssignmentPerGroupMembershipValidator, attributes: [:assignments, :group_memberships]
  validates_with AssignmentGroupPresentValidator, attributes: [:assignment_groups]

  scope :approved, -> { where approved: "Approved" }
  scope :rejected, -> { where approved: "Rejected" }
  scope :pending, -> { where approved: "Pending" }
  scope :order_by_name, -> { order "name ASC" }

  clean_html :text_proposal

  # Instructors need to approve a group before the group is allowed to proceed
  def approved?
    approved == "Approved"
  end

  def rejected?
    approved == "Rejected"
  end

  def pending?
    approved == "Pending"
  end

  def same_name_as?(another_group)
    name.downcase == another_group.name.downcase
  end

  # Group submissions
  def submission_for_assignment(assignment, submitted_only=true)
    submissions = submissions_by_assignment_id[assignment.id]
    if submissions.nil?
      nil
    else
      submitted_only ? submissions.reject(&:unsubmitted?).try(:first) : submissions.try(:first)
    end
  end

  def submitter_directory_name
    Formatter::Filename.new(name).directory_name.filename
  end

  def submitter_directory_name_with_suffix
    "#{submitter_directory_name} - #{id}"
  end

  # Grabbing the grade for an assignment
  def grade_for_assignment(assignment)
    grades.where(assignment_id: assignment.id).first || grades.new(assignment: assignment)
  end

  private

  def submissions_by_assignment_id
    @submissions_by_assignment ||= submissions.group_by(&:assignment_id)
  end

  def cache_associations
    self.course_id ||= assignments.first.try(:course_id)
  end
end
