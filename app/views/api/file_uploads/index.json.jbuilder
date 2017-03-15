json.data @file_uploads do |file_upload|
  json.type "file_uploads"
  json.id file_upload.id.to_s

  json.attributes do
    json.merge! file_upload.attributes
  end
end
