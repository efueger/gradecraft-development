feature "editing a badge" do
  context "as a professor" do
    let(:course) { build :course, has_badges: true}
    let!(:course_membership) { create :course_membership, :professor, user: professor, course: course }
    let(:professor) { create :user }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course}

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Badges"
      end

      expect(current_path).to eq badges_path

      within(".pageContent") do
        click_link "Fancy Badge"
      end

      expect(current_path).to eq badge_path(badge.id)

      within(".context_menu") do
        click_link "Edit"
      end

      within(".pageContent") do
        fill_in "Name", with: "Edited Badge Name"
        click_button "Update Badge"
      end
      expect(page).to have_notification_message("notice", "Edited Badge Name Badge successfully updated")
    end
  end
end
