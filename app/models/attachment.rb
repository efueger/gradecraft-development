class Attachment < ActiveRecord::Base
  belongs_to :grade
  belongs_to :file_upload

  validates_presence_of :grade
  validates_presence_of :file_upload

  accepts_nested_attributes_for :file_upload
end
