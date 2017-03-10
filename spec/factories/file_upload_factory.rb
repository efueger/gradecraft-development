FactoryGirl.define do
  factory :file_upload do
    filename "test_file.rb"
    file { fixture_file("test_image.jpg", "img/jpg") }
  end
end
