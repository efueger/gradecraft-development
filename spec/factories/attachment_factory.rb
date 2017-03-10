FactoryGirl.define do
  factory :attachment do
    association :file_upload
    association :grade
    file { fixture_file("test_image.jpg", "img/jpg") }
  end
end
