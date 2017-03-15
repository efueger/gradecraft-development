describe UploadsController do
  let(:controller_instance) { UploadsController.new }
  let(:submission_file) { create(:submission_file) }
  let(:course) { create(:course) }
  let(:student) { create(:user) }
  let!(:student_course_membership) { create(:course_membership, :student, user: student) }
  let(:stub_submission_file) { allow(SubmissionFile).to receive(:find).with(submission_file.id) { submission_file }}

  before(:each) do
    login_user(student)
    request.env["HTTP_REFERER"] = "localhost:8000"
  end

  describe "#remove" do
    subject { get :remove, params: { model: "SubmissionFile", upload_id: submission_file.id }}

    it "fetches the upload" do
      controller.instance_variable_set(:@upload, submission_file)
      expect(controller).to receive(:fetch_upload_with_model)
      subject
    end

    it "deletes the upload from s3" do
      stub_submission_file
      expect(submission_file).to receive(:delete_from_s3)
      subject
    end

    it "sets the upload to an ivar" do
      subject
      expect(assigns(:upload)).to eq(submission_file)
    end

    it "redirects back to where you were" do
      subject
      expect(response).to redirect_to("localhost:8000")
    end

    context "upload was successfully deleted from s3" do
      before { allow(submission_file).to receive(:exists_on_s3?) { false }}

      it "destroys the upload" do
        stub_submission_file
        expect(submission_file).to receive(:destroy)
        subject
      end

      it "destroys the upload with flash" do
        expect(controller).to receive(:destroy_upload_with_flash)
        subject
      end
    end

    context "upload failed to delete from s3" do
      before { allow(submission_file).to receive(:exists_on_s3?) { true }}
      it "sets a flash alert" do
        stub_submission_file
        subject
        expect(flash[:alert]).to match(/File failed to delete from the server/)
      end
    end
  end

  describe "#upload_class" do
    subject { controller_instance.instance_eval { upload_class } }
    before { allow(controller_instance).to receive(:params) { model_params }}

    context "model is passed in camelcased format" do
      let(:model_params) { ActionController::Parameters.new model: "SubmissionFile" }
      it "returns the upload klass" do
        expect(subject).to eq(SubmissionFile)
      end
    end

    context "model is passed in underscored format" do
      let(:model_params) { ActionController::Parameters.new model: "submission_file" }
      it "still returns the upload klass" do
        expect(subject).to eq(SubmissionFile)
      end
    end
  end

  describe "#destroy_upload_with_flash" do
    subject { controller_instance.instance_eval { destroy_upload_with_flash } }

    before(:each) do
      controller_instance.request = ActionDispatch::Request.new("rack.input" => [])
      controller_instance.instance_variable_set(:@upload, submission_file)
    end

    it "destroys the upload" do
      expect(submission_file).to receive(:destroy)
      subject
    end

    context "upload destroys successfully" do
      before { allow(submission_file).to receive(:destroy) { true }}
      it "sets a success message" do
        subject
        expect(controller_instance.flash[:success]).to match(/File was successfully removed/)
      end
    end

    context "upload fails to destroy" do
      before { allow(submission_file).to receive(:destroy) { false }}
      it "sets an alert message" do
        subject
        expect(controller_instance.flash[:alert]).to match(/File was deleted/)
      end
    end
  end

  describe "#fetch_upload_with_model" do
    let(:upload_params) { ActionController::Parameters.new upload_id: submission_file.id }

    subject { controller_instance.instance_eval { fetch_upload_with_model } }

    before(:each) do
      controller_instance.instance_variable_set(:@upload, submission_file)
      allow(controller_instance).to receive(:upload_class) { SubmissionFile }
      allow(controller_instance).to receive(:params) { upload_params }
    end

    it "fetches the upload" do
      expect(SubmissionFile).to receive(:find).with(submission_file.id)
      subject
    end

    it "sets an @upload ivar" do
      subject
      expect(controller_instance.instance_variable_get(:@upload)).to eq(submission_file)
    end
  end

  describe "all possible upload file classes" do
    before(:each) { subject }

    context ":model param is ChallengeFile" do
      let(:challenge_file) { create(:challenge_file) }
      subject { get :remove, params: { model: "ChallengeFile", upload_id: challenge_file.id }}

      it "returns a ChallengeFile object" do
        expect(assigns(:upload).class).to eq(ChallengeFile)
      end

      it "returns the correct ChallengeFile" do
        expect(assigns(:upload).id).to eq(challenge_file.id)
      end
    end

    context ":model param is BadgeFile" do
      let(:badge_file) { create(:badge_file) }
      subject { get :remove, params: { model: "BadgeFile", upload_id: badge_file.id }}

      it "returns a BadgeFile object" do
        expect(assigns(:upload).class).to eq(BadgeFile)
      end

      it "returns the correct BadgeFile" do
        expect(assigns(:upload).id).to eq(badge_file.id)
      end
    end

    context ":model param is AssignmentFile" do
      let(:assignment_file) { create(:assignment_file) }
      subject { get :remove, params: { model: "AssignmentFile", upload_id: assignment_file.id }}

      it "returns a AssignmentFile object" do
        expect(assigns(:upload).class).to eq(AssignmentFile)
      end

      it "returns the correct AssignmentFile" do
        expect(assigns(:upload).id).to eq(assignment_file.id)
      end
    end
  end
end
