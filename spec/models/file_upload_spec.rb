describe FileUpload do
  subject { grade.file_uploads.new image_file_attrs }

  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:grade) { build(:grade, course: course, assignment: assignment) }
  let(:new_attachment) { grade.file_uploads.new image_file_attrs }

  extend Toolkits::Models::Shared::Files
  define_context # pull in attrs for image and text files

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a filename" do
      subject.filename = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:filename]).to include "can't be blank"
    end
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      subject.grade.save!
      expect(subject.grade_id).to equal grade.id
      expect(subject.new_record?).to be_falsey
    end

    it "is deleted when the parent submission is destroyed" do
      subject.grade.save!
      expect {grade.destroy}.to change(FileUpload, :count).by(-1)
    end
  end

  describe "uploading multiple files" do
    it "accepts multiple files" do
      grade.file_uploads.new text_file_attrs
      subject.grade.save!
      expect(grade.file_uploads.count).to equal 2
    end
  end

  describe "formatting name of mounted file" do
    subject { new_attachment.read_attribute(:file) }
    let(:save_grade) { new_attachment.grade.save! }

    it "accepts text files as well as images" do
      new_attachment.file = fixture_file("test_file.txt", "txt")
      save_grade
      expect expect(subject).to match(/\d+_test_file\.txt/)
    end

    it "has an accessible url" do
      save_grade
      expect expect(subject).to match(/\d+_test_image\.jpg/)
    end

    it "shortens and removes non-word characters from file names on save" do
      new_attachment.file = fixture_file("Too long, strange characters, and Spaces (In) Name.jpg", "img/jpg")
      save_grade
      expect(subject).to match(/\d+_too_long__strange_characters__and_spaces_\.jpg/)
    end
  end

  describe "url" do
    subject { new_attachment.url }
    before { allow(new_attachment).to receive_message_chain(:s3_object, :presigned_url) { "http://some.url" }}

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
