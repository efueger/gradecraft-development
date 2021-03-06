describe "api/badges/index" do
  before(:all) do
    @course = create(:course, badge_term: "baj")
    @student = create(:user)
  end

  before(:each) do
    @badge = create(:badge, description: "...")
    @badges = [@badge]
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:current_user).and_return(double(:user, is_staff?: false, id: 555))
  end

  it "responds with an array of badges" do
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(1)
  end

  it "does not include badges invisible to students" do
    @badge.update(visible: false)
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(0)
  end

  it "does include invisible badges for staff" do
    allow(@badge).to receive(:visible?).and_return(false)
    allow(view).to receive(:current_user).and_return(double(:gsi, is_staff?: true))
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(1)
  end

  it "adds the icon url to the badges" do
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["icon"]).to eq(@badge.icon.url)
  end

  it "adds the total earned points to the badges" do
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["total_earned_points"]).to eq(@badge.earned_badge_total_points_for_student(@student))
  end

  it "adds the earned badge count to the badges" do
    allow(@badge).to receive(:earned_badge_count_for_student).and_return(5)
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["earned_badge_count"]).to eq(5)
  end

  describe "passes boolean states for icons" do
    it "adds has_info to model" do
      render
      json = JSON.parse(response.body)
      expect(json["data"][0]["attributes"]["has_info"]).to be_truthy
    end

    it "adds is_locked to model" do
      allow(@badge).to receive(:is_unlocked_for_student?).and_return(false)
      render
      json = JSON.parse(response.body)
      expect(json["data"][0]["attributes"]["is_locked"]).to be_truthy
    end

    it "adds has_been_unlocked to model" do
      allow(@badge).to receive(:is_unlocked_for_student?).and_return(true)
      allow(@badge).to receive(:is_unlockable?).and_return(true)
      render
      json = JSON.parse(response.body)
      expect(json["data"][0]["attributes"]["has_been_unlocked"]).to be_truthy
    end

    it "adds is_a_condition to model" do
      allow(@badge).to receive(:is_a_condition?).and_return(true)
      render
      json = JSON.parse(response.body)
      expect(json["data"][0]["attributes"]["is_a_condition"]).to be_truthy
    end
  end

  it "includes unlock keys when badge is an unlock condition" do
    assignment = create(:assignment)
    unlock_key = create(:unlock_condition, unlockable: assignment, unlockable_type: "Assignment", condition: @badge, condition_type: "Badge")
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["unlock_keys"]).to eq(["#{assignment.name} is unlocked by #{unlock_key.condition_state} #{@badge.name}"])
  end

  it "includes unlock conditions when badge is a unlockable" do
    assignment = create(:assignment)
    unlock_condition = create(:unlock_condition, unlockable: @badge, unlockable_type: "Badge", condition: assignment, condition_type: "Assignment")
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["unlock_conditions"]).to eq(["#{assignment.name} must be #{unlock_condition.condition_state}"])
  end

  it "renders term for badge, badges" do
    render
    json = JSON.parse(response.body)
    expect(json["meta"]["term_for_badge"]).to eq("baj")
    expect(json["meta"]["term_for_badges"]).to eq("bajs")
  end

  it "includes call to update" do
    @allow_updates = true
    render
    json = JSON.parse(response.body)
    expect(json["meta"]["allow_updates"]).to be_truthy
  end
end
