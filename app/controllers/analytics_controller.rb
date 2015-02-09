class AnalyticsController < ApplicationController
  before_filter :ensure_staff?
  before_filter :set_granularity_and_range

  def index
    @title = "User Analytics"
    @students = current_course.students.order('last_name ASC')
  end

  def students
    @title = "#{term_for :student} Analytics"
  end

  def staff
    @title = "Staff Analytics"
  end

  def all_events
    data = CourseEvent.data(@granularity, @range, {course_id: current_course.id}, {event_type: "_all"})

    render json: data
  end

  # Displaying the top 10 and bottom 10 students for quick overview
  def top_10
    @title = "Top 10/Bottom 10"
    students = current_course.students_being_graded
    students.each do |s|
      s.score = s.cached_score_for_course(current_course)
    end
    @students = students.to_a.sort_by {|student| student.score}.reverse
    if @students.length < 20
      @top_ten_students = @bottom_ten_students = []
    else
      @top_ten_students = @students[0..9]
      @bottom_ten_students = @students[-10..-1]
    end
  end

  # Displaying per assignment summary outcome statistics
  def per_assign
    @assignment_types = current_course.assignment_types.sorted
  end

  # Display per team summary scores
  def team_grade
    #respond_with @assignments = current_course.assignments.order('name ASC').select {|a| a.grades.released.length > 1}
  end

  def role_events
    data = CourseRoleEvent.data(@granularity, @range, {course_id: current_course.id, role_group: params[:role_group]}, {event_type: "_all"})

    render json: data
  end

  def assignment_events
    assignments = Hash[current_course.assignments.select([:id, :name]).collect{ |h| [h.id, h.name] }]
    data = AssignmentEvent.data(@granularity, @range, {assignment_id: assignments.keys}, {event_type: "_all"})

    data.decorate! { |result| result[:name] = assignments[result.assignment_id] }

    render json: data
  end

  def login_frequencies
    data = CourseLogin.data(@granularity, @range, {course_id: current_course.id})

    data[:lookup_keys] = ['{{t}}.average']
    data.decorate! do |result|
      result[:name] = "Average #{data[:granularity]} login frequency"
      # Get frequency
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] = (values['total'] / values['count']).round(2)
      end
    end

    render json: data
  end

  def role_login_frequencies
    data = CourseRoleLogin.data(@granularity, @range, {course_id: current_course.id, role_group: params[:role_group]})

    data[:lookup_keys] = ['{{t}}.average']
    data.decorate! do |result|
      result[:name] = "Average #{data[:granularity]} login frequency"
      # Get frequency
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] = (values['total'] / values['count']).round(2)
      end
    end

    render json: data
  end

  def login_events
    data = CourseLogin.data(@granularity, @range, {course_id: current_course.id})

    # Only graph counts
    data[:lookup_keys] = ['{{t}}.count']

    render json: data
  end

  def login_role_events
    data = CourseRoleLogin.data(@granularity, @range, {course_id: current_course.id, role_group: params[:role_group]})

    # Only graph counts
    data[:lookup_keys] = ['{{t}}.count']

    render json: data
  end

  def all_pageview_events
    data = CoursePageview.data(@granularity, @range, {course_id: current_course.id}, {page: "_all"})

    render json: data
  end

  def all_role_pageview_events
    data = CourseRolePageview.data(@granularity, @range, {course_id: current_course.id, role_group: params[:role_group]}, {page: "_all"})

    render json: data
  end

  def all_user_pageview_events
    user = current_course_data.students.find(params[:user_id])
    data = CourseUserPageview.data(@granularity, @range, {course_id: current_course.id, user_id: user.id}, {page: "_all"})

    render json: data
  end

  def pageview_events
    data = CoursePagePageview.data(@granularity, @range, {course_id: current_course.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: data
  end

  def role_pageview_events
    data = CourseRolePagePageview.data(@granularity, @range, {course_id: current_course.id, role_group: params[:role_group]})
    data.decorate! { |result| result[:name] = result.page }

    render json: data
  end

  def user_pageview_events
    user = current_course_data.students.find(params[:user_id])
    data = CourseUserPagePageview.data(@granularity, @range, {course_id: current_course.id, user_id: user.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: data
  end

  def prediction_averages
    data = CoursePrediction.data(@granularity, @range, {course_id: current_course.id})

    data[:lookup_keys] = ['{{t}}.average']
    data.decorate! do |result|
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] = (values['total'] / values['count'] * 100).to_i
      end
    end

    render json: data
  end

  def assignment_prediction_averages
    assignments = Hash[current_course.assignments.select([:id, :name]).collect{ |h| [h.id, h.name] }]
    data = AssignmentPrediction.data(@granularity, @range, {assignment_id: assignments.keys})

    data[:lookup_keys] = ['{{t}}.count','{{t}}.total']
    data.decorate! do |result|
      result[:name] = assignments[result.assignment_id]
    end

    render json: data
  end

  private
  def set_granularity_and_range

    @granularity = :daily

    if current_course.start_date && current_course.end_date
      @range = (current_course.start_date..current_course.end_date)
    else
      @range = :past_year
    end
  end
end
