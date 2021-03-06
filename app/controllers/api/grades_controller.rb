require_relative "../../services/updates_grade"

class API::GradesController < ApplicationController

  before_action :ensure_staff?

  # GET api/assignments/:assignment_id/students/:student_id/grade
  def show
    if Assignment.exists?(params[:assignment_id].to_i) && User.exists?(params[:student_id].to_i)
      @grade = Grade.find_or_create(params[:assignment_id], params[:student_id])
      if @grade.assignment.release_necessary?
        @grade_status_options = Grade::STATUSES
      else
        @grade_status_options = Grade::UNRELEASED_STATUSES
      end
    else
      render json: {
        message: "not a valid student or assignment", success: false
        },
        status: 400
    end
  end

  # POST api/grades/:grade_id
  def update
    grade = Grade.find(params[:id])
    result = Services::UpdatesGrade.update grade, grade_params, current_user.id
    if result
      @grade = result.grade
      render "api/grades/show", success: true, status: 200
    else
      render json: {
        message: "failed to save grade", success: false
        },
        status: 400
    end
  end

  # GET api/assignments/:assignment_id/groups/:group_id/grades
  def group_index
    @assignment = Assignment.find(params[:assignment_id])
    if !@assignment.has_groups?
      render json: {
        message: "not a group assignment", success: false
        },
        status: 400
    else
      students = Group.find(params[:group_id]).students
      @student_ids = students.pluck(:id)
      @grades =
        Grade.find_or_create_grades(params[:assignment_id], @student_ids).order_by_student
      @criterion_grades = CriterionGrade.where(grade_id: @grades.pluck(:id))
      if @assignment.release_necessary?
        @grade_status_options = Grade::STATUSES
      else
        @grade_status_options = Grade::UNRELEASED_STATUSES
      end
    end
  end

  private

  def grade_params
    params.require(:grade).permit(:adjustment_points, :adjustment_points_feedback,
      :feedback, :group_id, :pass_fail_status, :raw_points, :status )
  end
end
