require "active_record_spec_helper"
require "./app/importers/grade_importers/canvas_grade_importer"

describe CanvasGradeImporter do
  describe "#import" do
    it "returns empty results if there are no canvas grades" do
      result = described_class.new(nil).import(nil, nil)

      expect(result.successful).to be_empty
      expect(result.unsuccessful).to be_empty
    end

    context "with some canvas grades" do
      let(:assignment) { create :assignment }
      let(:canvas_grade) do
        {
          id: canvas_grade_id,
          score: 98.0,
          user_id: "USER_1"
        }.stringify_keys
      end
      let(:canvas_user) do
        {
          primary_email: user.email
        }.stringify_keys
      end
      let(:canvas_grade_id) { "GRADE_1" }
      let(:grade) { Grade.unscoped.last }
      let(:syllabus) { double(:syllabus, user: canvas_user) }
      let(:user) { create :user }
      subject { described_class.new([canvas_grade]) }

      it "creates the grade" do
        expect { subject.import(assignment.id, syllabus) }.to \
          change { Grade.count }.by 1
        expect(grade.assignment).to eq assignment
        expect(grade.student).to eq user
        expect(grade.raw_points).to eq 98
      end

      it "creates a link to the grade id in canvas" do
        subject.import(assignment.id, syllabus)

        imported_grade = ImportedGrade.unscoped.last
        expect(imported_grade.grade).to eq grade
        expect(imported_grade.provider).to eq "canvas"
        expect(imported_grade.provider_resource_id).to eq canvas_grade_id
      end

      it "contains a successful row if the grade is valid" do
        result = subject.import(assignment.id, syllabus)

        expect(result.successful.count).to eq 1
        expect(result.successful.last).to eq grade
      end

      it "contains an unsuccessful row if the grade is not valid" do
        allow_any_instance_of(Grade).to receive(:save).and_return false
        allow_any_instance_of(Grade).to receive(:errors)
          .and_return(double(:errors, full_messages: ["Something is wrong"]))

        result = subject.import(assignment.id, syllabus)

        expect(result.unsuccessful.count).to eq 1
        expect(result.unsuccessful.first[:errors]).to eq "Something is wrong"
      end
    end
  end
end
