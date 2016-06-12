require "rails_spec_helper"

describe InfoController do
  before(:all) { @course = create(:course) }
  before(:all) { @course_2 = create(:course) }
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
      CourseMembership.create user: @professor, course: @course_2, role: "professor"
    end
    before { login_user(@professor) }

    describe "GET dashboard" do
      it "retrieves the dashboard" do
        @assignment = create(:assignment, course: @course)
        get :dashboard
        expect(response).to render_template(:dashboard)
      end
    end

    describe "GET timeline_events" do
      it "retrieves the timeline events" do
        get :timeline_events
        expect(response).to render_template("info/_timeline")
      end
    end

    describe "GET awarded_badges" do
      it "retrieves the awarded badges page" do
        get :awarded_badges
        expect(response).to render_template(:awarded_badges)
      end
    end

    describe "GET grading_status" do
      it "retrieves the grading_status page" do
        get :grading_status
        expect(response).to render_template(:grading_status)
      end
    end

    describe "GET top_10" do
      before(:all) do
        student = create(:user)
        student_2 = create(:user)
        student_3 = create(:user)
        student_4 = create(:user)
        student_5 = create(:user)
        student_6 = create(:user)
        student_7 = create(:user)
        student_8 = create(:user)
        student_9 = create(:user)
        student.courses << @course
        student_2.courses << @course
        student_3.courses << @course
        student_4.courses << @course
        student_5.courses << @course
        student_6.courses << @course
        student_7.courses << @course
        student_8.courses << @course
        student_9.courses << @course
      end

      it "returns the Top 10/Bottom 10 page for the current course" do
        session[:course_id] = @course.id
        get :top_10
        expect(assigns(:title)).to eq("Top 10/Bottom 10")
        expect(response).to render_template(:top_10)
      end

      it "shows the top 10 if there are less than ten students" do
        get :top_10
        expect(response).to render_template(:top_10)
        expect(assigns(:top_ten_students).present?).to be true
        expect(assigns(:bottom_ten_students)).to be nil
      end

      it "shows the top and bottom students if less than 20 students" do
        student_10 = create(:user)
        student_11 = create(:user)
        student_12 = create(:user)
        student_10.courses << @course
        student_11.courses << @course
        student_12.courses << @course
        get :top_10
        expect(assigns(:top_ten_students).present?).to be true
        expect(assigns(:bottom_ten_students).present?).to be true
      end
    end

    describe "GET per_assign" do
      it "returns the Assignment Analytics page for the current course" do
        get :per_assign
        expect(assigns(:title)).to eq("Assignment Analytics")
        expect(response).to render_template(:per_assign)
      end
    end

    describe "GET gradebook" do
      it "retrieves the gradebook" do
        expect(GradebookExporterJob).to \
          receive(:new).with(user_id: @professor.id, course_id: @course.id)
            .and_call_original
        expect_any_instance_of(GradebookExporterJob).to receive(:enqueue)
        get :gradebook
      end

      it "redirects to the root path if there is no referer" do
        get :gradebook
        expect(response).to redirect_to root_path
      end

      it "redirects to the referer if there is one" do
        request.env["HTTP_REFERER"] = dashboard_path
        get :gradebook
        expect(response).to redirect_to dashboard_path
      end
    end

    describe "GET multipled_gradebook" do
      it "retrieves the multiplied gradebook" do
        expect(MultipliedGradebookExporterJob).to \
          receive(:new).with(user_id: @professor.id, course_id: @course.id)
            .and_call_original
        expect_any_instance_of(MultipliedGradebookExporterJob).to receive(:enqueue)
        get :multiplied_gradebook
      end

      it "redirects to the root path if there is no referer" do
        get :multiplied_gradebook
        expect(response).to redirect_to root_path
      end

      it "redirects to the referer if there is one" do
        request.env["HTTP_REFERER"] = dashboard_path
        get :multiplied_gradebook
        expect(response).to redirect_to dashboard_path
      end
    end

    describe "GET final_grades" do
      it "retrieves the final_grades download" do
        get :final_grades, format: :csv
        expect(response.body).to include("First Name,Last Name,Email,Username,Score,Grade")
      end
    end

    describe "GET research_gradebook" do
      it "retrieves the research gradebook" do
        expect(GradeExportJob).to \
          receive(:new).with(user_id: @professor.id, course_id: @course.id)
            .and_call_original
        expect_any_instance_of(GradeExportJob).to receive(:enqueue)
        get :research_gradebook
      end

      it "redirects to the root path if there is no referer" do
        get :research_gradebook
        expect(response).to redirect_to root_path
      end

      it "redirects to the referer if there is one" do
        request.env["HTTP_REFERER"] = dashboard_path
        get :research_gradebook
        expect(response).to redirect_to dashboard_path
      end
    end

    describe "GET choices" do
      it "retrieves the choices" do
        get :choices
        expect(assigns(:title)).to eq("Multiplier Choices")
        expect(response).to render_template(:choices)
      end

      it "only shows the students for the team" do
        @team = create(:team, course: @course)
        @student = create(:user)
        @student.courses << @course
        @student.teams << @team
        @student_2 = create(:user)
        @student_2.courses << @course
        get :choices, team_id: @team.id
        expect(response).to render_template(:choices)
        expect(assigns(:students)).to eq([@student])
      end
    end
  end

  context "as a student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
      @student.courses << @course_2
    end
    before(:each) { login_user(@student) }

    describe "GET dashboard" do
      it "retrieves the dashboard if turned on" do
        get :dashboard
        expect(response).to render_template(:dashboard)
      end
    end

    describe "GET timeline_events" do
      it "retrieves the timeline events" do
        get :timeline_events
        expect(response).to render_template("info/_timeline")
      end
    end

    describe "protected routes" do
      [
        :awarded_badges,
        :grading_status,
        :top_10,
        :per_assign,
        :gradebook,
        :multiplied_gradebook,
        :final_grades,
        :research_gradebook,
        :choices
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route).to redirect_to(:root)
        end
      end
    end
  end
end
