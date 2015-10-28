require "active_record_spec_helper"

describe Team do
  describe "validations" do
    let(:course) { create :course }

    it "requires that the team name be unique per course" do
      create :team, course_id: course.id, name: "Zeppelin"
      team = Team.new course_id: course.id, name: "zeppelin"
      expect(team).to_not be_valid
      expect(team.errors[:name]).to include "has already been taken"
    end

    it "can have the same name if it's for a different course" do
      create :team, course_id: course.id, name: "Zeppelin"
      team = Team.new course_id: create(:course).id, name: "Zeppelin"
      expect(team).to be_valid
    end
  end

  describe ".find_by_course_and_name" do
    let(:team) { create :team }

    it "returns the team for the specific course id and name" do
      result = Team.find_by_course_and_name team.course_id, team.name.upcase
      expect(result).to eq team
    end
  end

  describe "challenge_grade_score" do
  end

  describe "revised_team_score" do
    let(:course) { create :course }
    let(:team) { create(:team, course: course) }

    context "course is using team average for team score" do
      it "returns the average points for the team" do
        allow(course).to receive(:team_score_average) { true }
        allow(team).to receive(:average_points) { 500 }
        expect( team.instance_eval { revised_team_score } ).to eq(500)
      end
    end

    context "course is using challenge grade total for team score" do
      it "returns the challenge grade score for the team" do
        allow(course).to receive(:team_score_average) { false }
        allow(team).to receive(:challenge_grade_score) { 3000 }
        expect( team.instance_eval { revised_team_score } ).to eq(3000)
      end
    end
  end
end
