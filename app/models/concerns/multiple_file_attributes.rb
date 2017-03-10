# Define file attributes on models for inclusion of multiple files in strong params.
#
# example
#   def badge_params
#     params.require(:badge).permit(...,
#       badge_files_attributes: [:id, file: []])
#   end
#
# Note: These are not currently used on Grades (file_uploads_attributes)
# since grade files are uploaded via AJAX in Angular, and not submitted through
# any form data.

module MultipleFileAttributes
  extend ActiveSupport::Concern

  class_methods do
    def multiple_files(files_attributes)
      define_method "#{files_attributes}_attributes=" do |attributes|
        files = attributes["0"]["file"]
        super files.map { |f| { file: f, filename: f.original_filename } }
      end
    end
  end
end
