describe FileUpload , focus: true do

  # currently we need the course_number to build the attachments directory
  let(:course) { create(:course, course_number: "101") }
  let(:assignment) { create(:assignment, course: course) }
  let(:grade) { create(:grade, course: course, assignment: assignment) }
  let(:file) { create(:file_upload, course: course, assignment: assignment)}
  let(:file2) { create(:file_upload, course: course, assignment: assignment)}
  let(:attachment) { build(:attachment, grade: grade, file_upload: file)}

  subject { file }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a filename" do
      subject.filename = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:filename]).to include "can't be blank"
    end
  end

  describe "grade association" do
    before do
      attachment.save
    end

    it "accepts a file through an attachment" do
      expect(grade.file_uploads.count).to equal 1
    end

    it "accepts multiple files through attachments" do
      create(:attachment, grade: grade, file_upload: file2)
      expect(grade.file_uploads.count).to equal 2
    end
  end

  describe "formatting name of mounted file" do

    it "has a filename and url based off of the original file" do
      subject.save!
      expect(subject.filename).to eq("original_file_name")
      expect(subject.url).to match(/\d+_test_image\.jpg/)
    end

    it "shortens and removes non-word characters from file names on save" do
      odd_file = create(:file_upload,
        course: course,
        assignment: assignment,
        file: fixture_file("Too long, strange characters, and Spaces (In) Name.jpg", "img/jpg")
      )
      expect(odd_file.file.filename).to match(/\d+_too_long__strange_characters__and_spaces_\.jpg/)
    end
  end

  describe "url" do
    subject { file.url }
    before { allow(file).to receive_message_chain(:s3_object, :presigned_url) { "http://some.url" }}

    it "returns the presigned amazon url" do
      expect(subject).to eq("http://some.url")
    end
  end

  describe "#course" do
    it "returns the associated course" do
      expect(subject.course).to eq(course)
    end
  end

  describe "#assignment" do
    it "returns the associated assignment" do
      expect(subject.assignment).to eq(assignment)
    end
  end

  describe "S3Manager::Carrierwave inclusion" do
    let(:file_upload) { build(:file_upload) }

    it "can be deleted from s3" do
      expect(file_upload.respond_to?(:delete_from_s3)).to be_truthy
    end

    it "can check whether it exists on s3" do
      expect(file_upload.respond_to?(:exists_on_s3?)).to be_truthy
    end
  end
end
