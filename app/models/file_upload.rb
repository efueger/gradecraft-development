# This class currently handles grade files, it should be expanded to handle
# submission files and badge files to reduce the number of models needed
# to handle associated files. It is named FileUpload since "File" is
# already a ruby class.

class FileUpload < ActiveRecord::Base
  include S3Manager::Carrierwave

  has_many :attachments
  has_many :grades, through: :attachments, inverse_of: :file_uploads

  validates :filename, presence: true, length: { maximum: 50 }

  mount_uploader :file, AttachmentUploader
  process_in_background :file

  def klass_name
    "attachments"
  end
end
