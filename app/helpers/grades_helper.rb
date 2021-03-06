module GradesHelper
  extend SubmissionsHelper

  def grading_status_count_for(course)
    unreleased_grades_count_for(course) +
      in_progress_grades_count_for(course) +
      ungraded_submissions_count_for(course) +
      resubmission_count_for(course)
  end

  def in_progress_grades_count_for(course)
    Rails.cache.fetch(in_progress_grades_count_cache_key(course)) do
      course.grades.in_progress.count
    end
  end

  def in_progress_grades_count_cache_key(course)
    # This cache key is busted when a grade is updated
    "#{course.cache_key}/in_progress_grades_count"
  end

  def unreleased_grades_count_for(course)
    Rails.cache.fetch(unreleased_grades_count_cache_key(course)) do
      course.grades.not_released.count
    end
  end

  def unreleased_grades_count_cache_key(course)
    # This cache key is busted when a grade is updated
    "#{course.cache_key}/unreleased_grades_count"
  end

  # Returns the corresponding pass/fail status for a score
  # If the score is not a 0 or 1, the status will be nil
  def pass_fail_status_for(score)
    return status = "Pass" if score == 1
    return status = "Fail" if score == 0
    nil
  end
end
