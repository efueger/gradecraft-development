class API::RubricsController < ApplicationController

  # GET api/rubric/:id
  def show
    @rubric = current_course.rubrics.find params[:id]
    @criteria =
      @rubric.criteria.ordered.includes(:levels).order("levels.points").order("levels.sort_order").select(
        :id, :name, :description, :max_points, :order
      )
  end
end
