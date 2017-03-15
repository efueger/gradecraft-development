describe API::FileUploadsController do
  let(:course) { create :course, course_number: 101 }
  let(:professor) { create(:course_membership, :professor, course: course).user }
  let(:student) { create(:course_membership, :student, course: course).user }
  let(:grade) { create :grade, student: student, course: course }

  let(:group) { create :group }
  let(:group_assignment) { group.assignments.first }

  let(:file_upload) { create :file_upload, course: course, assignment: grade.assignment }
  let(:files) { [fixture_file("test_file.txt", "txt"), fixture_file("test_image.jpg", "img/jpg")] }


  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "adds upload files to grade" do
        expect {
          post :create, params: { grade_id: grade.id, file_uploads: files },
          format: :json
        }.to change { FileUpload.count }.by(2)
      end
    end

    describe "POST group_create" do
      it "creates a file upload once for each file" do
        expect {
          post :group_create, params: {
            assignment_id: group_assignment.id, group_id: group.id,
            file_uploads: files }, format: :json
        }.to change { FileUpload.count }.by(2)
      end

      it "attaches the uploaded files to each student's grade" do
        group.students.each do |student|
          create(:grade, student: student, assignment: group_assignment)
        end
        expect {
          post :group_create, params: {
            assignment_id: group_assignment.id, group_id: group.id,
            file_uploads: files }, format: :json
        }.to change { Attachment.count }.by(group.students.count * 2)
      end
    end

    describe "DELETE destroy" do
      it "destroys the grade file" do
        file_upload
        expect { delete :destroy, params: { id: file_upload.id }, format: :json
        }.to change { FileUpload.count }.by(-1)
      end

      it "removes the corresponding file on s3" do
        allow(FileUpload).to receive(:where) { [file_upload] }
        expect(file_upload).to receive(:delete_from_s3)
        delete :destroy, params: { id: file_upload.id }, format: :json
      end
    end
  end

  context "as student" do
    before(:each) { login_user(student) }

    describe "POST create" do
      it "is a protected route" do
        expect(post :create, params: { grade_id: grade.id }, format: :json).to \
          redirect_to(:root)
      end
    end

    describe "POST group_create" do
      it "is a protected route" do
        expect(post :group_create, params: {
            assignment_id: group.assignments.first.id,
            group_id: group.id }, format: :json
        ).to redirect_to(:root)
      end
    end

    describe "DELETE destroy" do
      it "is a protected route" do
        expect(delete :destroy, params: { id: file_upload.id }, format: :json
      ).to redirect_to(:root)
      end
    end
  end
end
