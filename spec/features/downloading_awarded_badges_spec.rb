feature "downloading awarded badges file" do
  context "as a professor" do
    let(:course) { build :course, has_badges: true }
    let!(:course_membership) { create :course_membership, :professor, user: professor, course: course }
    let(:professor) { create :user }
    let(:badge) { build :badge, course: course }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do

      within(".sidebar-container") do
        click_link "Course Data Exports"
      end

      within(".pageContent") do
        click_link "Awarded Badges"
      end

      expect(page.response_headers["Content-Type"]).to eq("text/csv")

      expect(page).to have_content "First Name,Last Name,Uniqname,Email,Badge ID,Badge Name,Feedback,Awarded Date"
    end
  end
end
