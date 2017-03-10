FactoryGirl.define do
  factory :attachment do
    association :file_upload
    association :grade
  end
end
