feature "deleting a challenge" do
  context "as a professor" do
    let(:course) { build :course, has_team_challenges: true}
    let!(:course_membership) { create :course_membership, :professor, user: professor, course: course }
    let(:professor) { create :user }
    let!(:challenge) { create :challenge, name: "Section Challenge Name", course: course }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Section Challenges"
      end

      expect(current_path).to eq challenges_path

      within(".pageContent") do
        click_link "Delete"
      end

      expect(page).to have_notification_message("notice", "Challenge Section Challenge Name successfully deleted")
    end
  end
end
