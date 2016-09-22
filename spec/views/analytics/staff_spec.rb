# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "analytics/staff" do

  before(:all) do
    @course = create(:course)
  end

  before(:each) do
    assign(:title, "Staff Analytics")
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
    assert_select "h2", text: "Staff Analytics", count: 1
  end

  it "renders the breadcrumbs" do
    render
    assert_select ".breadcrumbs" do
      assert_select "a", count: 2
    end
  end
end
