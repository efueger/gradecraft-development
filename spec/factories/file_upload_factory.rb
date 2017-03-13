FactoryGirl.define do
  factory :file_upload do
    filename "original_file_name"
    file { fixture_file("test_image.jpg", "img/jpg") }
  end
end
