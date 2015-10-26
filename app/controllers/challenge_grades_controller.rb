class ChallengeGradesController < ApplicationController

  before_filter :ensure_staff?, :except => [:show]

  def index
    @challenge = current_course.challenges.find(params[:challenge_id])
    redirect_to @challenge
  end

  def show
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = @challenge.challenge_grades.find(params[:id])
    @team = @challenge_grade.team
    @title = "#{@team.name}'s #{@challenge_grade.name} Grade"
  end

  def new
    @challenge = current_course.challenges.find(params[:challenge_id])
    @team = current_course.teams.find(params[:team_id])
    @teams = current_course.teams
    @challenge_grade = @team.challenge_grades.new
    @title = "Grading #{@team.name}'s #{@challenge.name}"
  end

  def edit
    @challenge = current_course.challenges.find(params[:challenge_id])
    @title = "Editing #{@challenge.name} Grade"
    @teams = current_course.teams
    @challenge_grade = @challenge.challenge_grades.find(params[:id])
  end

  # Grade many teams on a particular challenge at once
  def mass_edit
    @challenge = current_course.challenges.find(params[:challenge_id])
    @teams = current_course.teams
    @title = "Quick Grade #{@challenge.name}"
    @challenge_score_levels = @challenge.challenge_score_levels
    @students = current_course.students
    @challenge_grades = @teams.map do |t|
      @challenge.challenge_grades.where(:team_id => t).first || @challenge.challenge_grades.new(:team => t, :challenge => @challenge)
    end
  end

  def mass_update
    @challenge = current_course.challenges.find(params[:id])
    if @challenge.update_attributes(params[:challenge])
      redirect_to challenge_path(@challenge), notice: "#{@challenge.name} #{term_for :challenge} successfully graded"
    else
      redirect_to mass_edit_challenge_challenge_grades_path(@challenge)
    end
  end


  # @mz todo: refactor this whole thing, move into models and presenters
  def create
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = @challenge.challenge_grades.create(params[:challenge_grade])
    respond_to do |format|
      if @challenge_grade.save
        @course = current_course
        if current_course.add_team_score_to_student? and challenge_grade_is_student_visible?
          # @mz todo: substitute with ChallengeGrade#recalculate_team_scores method, revise specs
          @team = @challenge_grade.team
          @score_recalculator_jobs = @team.students.collect do |student|
            ScoreRecalculatorJob.new(user_id: student.id, course_id: current_course.id)
          end
          @score_recalculator_jobs.each(&:enqueue)
        end
        format.html { redirect_to @challenge, notice: "#{@challenge.name} #{term_for :challenge} successfully graded" }
        format.json { render json: @challenge, status: :created, location: @challenge_grade }
      else
        format.html { render action: "new" }
        format.json { render json: @challenge_grade.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def challenge_grade_is_student_visible?
      @challenge_grade.is_student_visible?
    end

  public

  # @mz todo: refactor this whole thing, move into models and presenters
  def update
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = current_course.challenge_grades.find(params[:id])
    respond_to do |format|
      if @challenge_grade.update_attributes(params[:challenge_grade])

        if current_course.add_team_score_to_student?
          if student_grades_require_update?
            # @mz todo: substitute with ChallengeGrade#recalculate_team_scores method, revise specs
            @team = @challenge_grade.team
            # @mz TODO: figure out how @team.students is supposed to be sorted in the controller
            @score_recalculator_jobs = @team.students.collect do |student|
              ScoreRecalculatorJob.new(user_id: student.id, course_id: current_course.id)
            end
            @score_recalculator_jobs.each(&:enqueue)
          end
        end

        format.html { redirect_to @challenge, notice: "Grade for #{@challenge.name} #{term_for :challenge} successfully updated" }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @challenge_grades.errors, status: :unprocessable_entity }
      end
    end
  end

  # @mz todo: refactor all of this nonsense, add specs etc, this works for now
  private

    def student_grades_require_update?
      score_update_required? or visibility_update_required?
    end

    def score_update_required?
      score_changed? and @challenge_grade.is_student_visible?
    end

    def visibility_update_required?
      visibility_changed? and @challenge_grade.is_student_visible?
    end

    def visibility_changed?
       @challenge_grade.previous_changes[:status].present?
    end

    def score_changed?
       @challenge_grade.previous_changes[:score].present?
    end

  public

    # # @mz todo: build out logic to trigger jobs in the event that the grades are student visible and the score changed, or if the grade became student invisible but used to be student visible

    # private
    # def student_grades_require_update?
    #   (score_changed? and @challenge_grade.is_student_visible?) or 
    #   (visibility_changed? and (was_released? or was_graded_and_became_invisible?))
    # end

    # def was_graded_and_became_invisible?
    #   was_graded? and is_in_progress? and not @challenge.release_necessary
    # end

    # def score_changed?
    #   @challenge_grade.previous_changes[:score].present?
    # end

    # def visibility_changed?
    #   @challenge_grade.previous_changes[:status].present?
    # end

    # def was_released?
    #   @challenge_grade.previous_changes[:status].first == "Released" rescue false
    # end

    # def was_graded?
    #   @challenge_grade.previous_changes[:status].first == "Graded" rescue false
    # end

    # def is_in_progress?
    #   @challenge_grade.previous_changes[:status].last == "In Progress" rescue false
    # end

    # public

    # Changing the status of a grade - allows instructors to review "Graded" grades, before they are "Released" to students
  def edit_status
    @challenge = current_course.challenges.find(params[:challenge_id])
    @title = "#{@challenge.name} Grade Statuses"
    @challenge_grades = @challenge.challenge_grades.find(params[:challenge_grade_ids])
  end

  def update_status
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grades = @challenge.challenge_grades.find(params[:challenge_grade_ids])
    @challenge_grades.each do |challenge_grade|
      challenge_grade.update_attributes!(params[:challenge_grade].reject { |k,v| v.blank? })
    end
    flash[:notice] = "Updated Grades!"
    redirect_to challenge_path(@challenge)
  end
 

  # @mz todo: add specs
  def destroy
    @challenge_grade = current_course.challenge_grades.find(params[:id])
    @challenge = current_course.challenges.find(@challenge_grade.challenge_id)

    @challenge_grade.destroy
    @challenge_grade.recalculate_student_and_team_scores 

    respond_to do |format|
      format.html { redirect_to challenge_path(@challenge) }
      format.json { head :ok }
    end
  end

end
