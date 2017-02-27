#= require spec_helper

describe 'gradeEdit directive', ()->

  beforeEach inject (_AssignmentService_,  _GradeService_, _RubricService_) ->

  describe 'for standard grades', ()->

    beforeEach ()->
      @http.whenGET("/api/assignments/1").respond(apiTestDoubles.assignment.standard)
      @http.whenGET("/api/assignments/1/students/99/grade/").respond(apiTestDoubles.grade.standard)
      @http.whenGET("/api/students/99/badges").respond(apiTestDoubles.badges)
      @element = @compile("<grade-edit assignment-id=1 recipient-type=student recipient-id=99 ></grade-edit>")(@rootScope)
      @rootScope.$digest()

    it 'loads the edit template', ()->
      expect($(@element).children("loading-message").length).toEqual(1)
      expect($(@element).children("article.grade-form-fields").length).toEqual(1)
      expect($(@element).find("grade-status-select").length).toEqual(1)
      expect($(@element).find("grade-submit-buttons").length).toEqual(1)
      expect($(@element).find("grade-last-updated").length).toEqual(1)

    it 'adds a raw points input for standard grades', ()->
      expect($(@element).find("input.adjustment-points-input").length).toEqual(1)

    it 'does not load inputs for pass/fail, score level or rubrics', ()->
      expect($(@element).find(".switch-socket").length).toEqual(0)
      expect($(@element).find("#rubric-grade-edit").length).toEqual(0)
      expect($(@element).find(".grade-score-level-selector").length).toEqual(0)

    it "includes a file uploader", ()->
      expect($(@element).find("grade-file-uploader").length).toEqual(1)
      expect(@element.html()).toContain("Upload Feedback or Enter Below")

  describe 'for group grades', ()->

    beforeEach ()->
      @http.whenGET("/api/assignments/2").respond(apiTestDoubles.assignment.standard)
      @http.whenGET("/api/assignments/2/groups/101/grades/").respond(apiTestDoubles.grade.group)
      @element = @compile("<grade-edit assignment-id=2 recipient-type=group recipient-id=101 ></grade-edit>")(@rootScope)
      @rootScope.$digest()

    it "does not include a file uploader", ()->
      expect($(@element).find("grade-file-uploader").length).toEqual(0)
      expect(@element.html()).toContain("Enter Text Feedback")
