describe API::GradesController do
  let(:course) { build :course}
  let(:student)  { create(:course_membership, :student, course: course).user }
  let(:professor) { create(:course_membership, :professor, course: course).user }
  let(:assignment) { create(:assignment, course: course) }
  let!(:grade) { create :grade, student: student, assignment: assignment }
  let(:group) { create(:group) }
  
  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET show" do
      it "returns a student's grade for the current assignment" do
        get :show,
          params: { assignment_id: assignment.id, student_id: student.id },
          format: :json
        expect(assigns(:grade).id).to eq(grade.id)
        expect(response).to render_template(:show)
      end

      it "assigns all options when release necessary" do
        assignment.update_attributes release_necessary: true
        get :show,
          params: { assignment_id: assignment.id, student_id: student.id },
          format: :json
        expect(assigns(:grade_status_options)).to eq(["In Progress", "Graded", "Released"])
      end

      it "assigns limited options when release not necessary" do
        get :show,
          params: { assignment_id: assignment.id, student_id: student.id },
          format: :json
        expect(assigns(:grade_status_options)).to eq(["In Progress", "Graded"])
      end
    end

    describe "update" do
      it "updates feedback, status and raw score from params" do
        post :update, params: { id: grade.id,
                                grade: { raw_points: 20000, feedback: "good jorb!",
                                         status: "Graded" }}, format: :json
        grade.reload
        expect(grade.feedback).to eq("good jorb!")
        expect(grade.status).to eq("Graded")
        expect(grade.raw_points).to eq(20000)
      end

      it "updates instructor modified to true" do
        post :update, params: { id: grade.id,
                                grade: { raw_points: 20000, feedback: "good jorb!" }
                                }, format: :json
        grade.reload
        expect(grade.instructor_modified).to be_truthy
      end

      it "timestamps the grade" do
        current_time = DateTime.now
        post :update, params: { id: grade.id,
                                grade: { raw_points: 20000, feedback: "good jorb!" }
                                }, format: :json
        expect(grade.reload.graded_at).to be > current_time
      end
    end

    describe "GET group_index" do
      before(:each) do
        assignment.groups << group
        group.students.each do |student|
          create(:grade, assignment_id: assignment.id, student_id: student.id)
        end
      end

      it "returns 400 error code with individual assignment" do
        assignment.update_attributes grade_scope: "Individual"
        get :group_index,
          params: { assignment_id: assignment.id, group_id: group.id },
          format: :json
        expect(response.status).to be(400)
      end

      it "returns criterion_grades and student ids for a group" do
        assignment.update_attributes grade_scope: "Group"
        get :group_index,
          params: { assignment_id: assignment.id, group_id: group.id },
          format: :json
        expect(assigns(:student_ids)).to eq(group.students.pluck(:id))
        expect(assigns(:grades).length).to eq(group.students.length)
        expect(response).to render_template(:group_index)
      end
    end
  end

  context "as student" do
    before(:each) { login_user(student) }

    describe "GET show" do
      it "is a protected route" do
        expect(get :show, params: {
          assignment_id: assignment.id, student_id: student.id
        }, format: :json).to redirect_to(:root)
      end
    end

    describe "PUT update" do
      it "is a protected route" do
        expect(post :update, params: { id: grade.id, raw_points: 20000 },
               format: :json).to redirect_to(:root)
      end
    end

    describe "GET group_index" do
      it "is a protected route" do
        expect(get :group_index,
               params: { assignment_id: assignment.id, group_id: 1 },
               format: :json).to redirect_to(:root)
      end
    end
  end
end
