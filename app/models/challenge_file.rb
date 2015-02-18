class ChallengeFile < ActiveRecord::Base
  include S3File

  attr_accessible :file, :filename, :filepath, :challenge_id

  belongs_to :challenge

  mount_uploader :file, AttachmentUploader
  process_in_background :file

end
