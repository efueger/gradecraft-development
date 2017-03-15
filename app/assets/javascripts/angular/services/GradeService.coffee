@gradecraft.service 'GradeService', ['GradeCraftAPI', 'DebounceQueue', '$http',
(GradeCraftAPI, DebounceQueue, $http) ->



  # We bind to modelGrade in the directives, to manage all grades through a
  # single object. On update, these params are copied over into each grade.
  # In this way individual and group grades can be treated the same.
  modelGrade = {}
  grades = []

  fileUploads = []
  criterionGrades = []

  gradeStatusOptions = []

  isRubricGraded = false
  thresholdPoints = 0

  # used to distinguish group and individual grades:
  _recipientType = ""
  _recipientId = ""

  #------- grade state management ---------------------------------------------#

  # Final points is unique to each grade in grades
  # when accounting for adjustment points
  _updateFinalPoints = (g)->
    g.raw_points = modelGrade.raw_points
    g.adjustment_points = parseInt(g.adjustment_points) || 0
    g.final_points = g.raw_points + g.adjustment_points
    g.final_points = 0 if g.final_points < thresholdPoints

  # This must be triggered whenever there is a
  # change to points fields or selected levels
  calculateGradePoints = ()->
    if isRubricGraded
      modelGrade.raw_points = _.sum(_.map(criterionGrades, "points"))
    modelGrade.raw_points = parseInt(modelGrade.raw_points) || 0
    _.each(grades, (g)->
      _updateFinalPoints(g))

  gradeIsPassing = ()->
    modelGrade.pass_fail_status == "Pass"

  setGradeToPass = ()->
    modelGrade.pass_fail_status = "Pass"

  toggeleGradePassFailStatus = ()->
    modelGrade.pass_fail_status =
      if modelGrade.pass_fail_status == "Pass" then "Fail" else "Pass"

  #------- grade API calls ----------------------------------------------------#

  # Adjustment fields and final_points are unique to each grade,
  # and are kept in the grades array. All other attributes are stored in the
  # singular grade object to simplify updates via binding in the directives
  _getGradeParams = (attributes)->
    angular.copy(attributes, modelGrade)
    delete modelGrade.adjustment_points
    delete modelGrade.adjustment_points_feedback
    delete modelGrade.final_points
    modelGrade.group_id = _recipientId if _recipientType == "group"

  # When we get a grade response for student or group,
  # this initial setup is run to extract all included and meta information
  _getIncluded = (response)->
    GradeCraftAPI.loadFromIncluded(fileUploads,"file_uploads", response.data)
    GradeCraftAPI.loadFromIncluded(criterionGrades,"criterion_grades", response.data)
    angular.copy(response.data.meta.grade_status_options, gradeStatusOptions)

    # - Uncomment this line if we want to force a status on autosave:
    # - If no status has been sent, we set status as "In Progress"
    # - to be returned on first autosave, in order to avoid faculty seeing
    # - partial grade information but no status.
    # - This will make the check for "disabled" on the submit buttons obsolete
    #  modelGrade.status = "In Progress" if ! modelGrade.status

    # We bind status changes to pending_status and only update on submit
    modelGrade.pending_status =  modelGrade.status
    thresholdPoints = response.data.meta.threshold_points
    isRubricGraded = response.data.meta.is_rubric_graded

  getGrade = (assignmentId, recipientType, recipientId)->
    _recipientType = recipientType
    _recipientId = recipientId
    if recipientType == "student"
      $http.get('/api/assignments/' + assignmentId + '/students/' + recipientId + '/grade/').then(
        (response) ->
          GradeCraftAPI.addItem(grades, "grades", response.data)
          _getGradeParams(response.data.data.attributes)
          _getIncluded(response)
          calculateGradePoints()
          GradeCraftAPI.logResponse(response)
        ,(response) ->
          GradeCraftAPI.logResponse(response)
      )
    else if recipientType == "group"
      $http.get('/api/assignments/' + assignmentId + '/groups/' + recipientId + '/grades/').then(
        (response) ->

          GradeCraftAPI.loadMany(grades, response.data)

          # Copy the first student's grade
          _getGradeParams(_.find(response.data.data,
            { attributes: {'student_id' : response.data.meta.student_ids[0] }
            }).attributes)
          _getIncluded(response)

          # The API sends criterion grades for all group members,
          # We filter to a single set from the first student
          filteredCriterionGrades = _.filter(criterionGrades, {'grade_id': modelGrade.id})
          angular.copy(filteredCriterionGrades, criterionGrades)

          calculateGradePoints()
          GradeCraftAPI.logResponse(response)
        ,(response) ->
          GradeCraftAPI.logResponse(response)
      )

  _updateGradeById = (id, params, returnURL=null)->
    $http.put("/api/grades/#{id}", grade: params).then(
      (response) ->
        modelGrade.updated_at = new Date()
        GradeCraftAPI.logResponse(response)
        if returnURL
          window.location = returnURL
      ,(response) ->
        GradeCraftAPI.logResponse(response)
    )

  _params = (id)->
    g = _.find(grades,{id: id})
    params = _.clone(modelGrade)
    params.adjustment_points = g.adjustment_points
    params.adjustment_points_feedback = g.adjustment_points_feedback
    params.final_points = g.final_points
    params

  _updateGrade = (returnURL=null)->
    if _recipientType == "student"
      params = _params(modelGrade.id)
      _updateGradeById(modelGrade.id, params, returnURL)
    else if _recipientType == "group"
      _.each(grades, (g)->
        params = _params(g.id)
        if returnURL && g == _.last(grades)
          _updateGradeById(g.id, params, returnURL)
        else
          _updateGradeById(g.id, params)
      )

  queueUpdateGrade = (immediate=false, returnURL=null) ->
    calculateGradePoints()
    DebounceQueue.addEvent(
      "grades", modelGrade.id, _updateGrade, [returnURL], immediate
    )

  _confirmMessage = ()->
    message = "Are you sure you want to submit the grade for this assignment?"
    if !isRubricGraded
      return message
    if _.every(criterionGrades, "level_id")
      message
    else
      message + " You still have criteria without a selected level."

  # Final "Submit Grade" actions, includes cleanup and redirect
  submitGrade = (returnURL=null)->
    if ! modelGrade.pending_status
      return alert "You must select a grade status before you can submit this grade"

    modelGrade.status =  modelGrade.pending_status

    return false unless confirm _confirmMessage()

    return queueUpdateGrade(true, returnURL) unless isRubricGraded

    # Rubric Grade Submission:

    # cancel all pending updates
    DebounceQueue.cancelEvent("grades", modelGrade.id)
    _.each(criterionGrades, (cg)->
      DebounceQueue.cancelEvent("criterion_grades", cg.criterion_id)
    )

    # parameters are configured to work with existing service
    # BuildsGrade: /services/creates_grade/builds_modelGrade.rb
    groupParams = _.map(grades, (g)->
      {
        student_id: g.student_id
        params: {
          grade: {
            adjustment_points: g.adjustment_points
            adjustment_points_feedback: g.adjustment_points_feedback
            feedback: modelGrade.feedback
            raw_points: modelGrade.raw_points
            status: modelGrade.status
          }
          criterion_grades: criterionGrades
        }
      }
    )

    # Iterate over group member's and submit grades:
    _.each(groupParams, (memberParams)->
      $http.put(
        "/api/assignments/#{modelGrade.assignment_id}/students/#{memberParams.student_id}/criterion_grades", memberParams.params
      ).then(
        (response) ->
          GradeCraftAPI.logResponse(response)
          if memberParams == _.last(groupParams)
            window.location = returnURL
        ,(response) ->
          GradeCraftAPI.logResponse(response)
      )
    )

#------- Criterion Grade Methods for Rubric Grading ---------------------------#

  findCriterionGrade = (criterionId)->
    return false unless isRubricGraded
    _.find(criterionGrades,{criterion_id: criterionId})

  addCriterionGrade = (criterionId, attr={})->
    return false unless isRubricGraded
    return false if findCriterionGrade(criterionId)

    criterionGrade = {
      "criterion_id": criterionId,
      "grade_id": modelGrade.id,
      "student_id": modelGrade.student_id,
      "level_id": null,
      "comments": null
    }
    criterionGrades.push(criterionGrade)

  setCriterionGradeLevel = (criterionId, level)->
    criterionGrade =
      findCriterionGrade(criterionId) || addCriterionGrade(criterionId)
    criterionGrade.level_id = level.id
    criterionGrade.points = level.points
    calculateGradePoints()

  _updateCriterionGrade = (criterionId)->
    criterionGrade = findCriterionGrade(criterionId)
    return false unless criterionGrade
    $http.put(
      "/api/assignments/#{modelGrade.assignment_id}/#{_recipientType}s/#{_recipientId}/criteria/#{criterionId}/update_fields",
      criterion_grade: criterionGrade
    ).then(
      (response) ->
        GradeCraftAPI.logResponse(response)
      ,(response) ->
        GradeCraftAPI.logResponse(response)
    )

  queueUpdateCriterionGrade = (criterionId, immediate=false) ->
    # using criterionId for queue id since we are not assured
    # to have a criterionGrade.id
    DebounceQueue.addEvent(
      "criterion_grades", criterionId, _updateCriterionGrade,
      [criterionId], immediate
    )

#------- Grade File Methods ---------------------------------------------------#

  # attachments to individual grades
  _postGradeFileUploads = (fd)->
    $http.post(
      "/api/grades/#{grade.id}/file_uploads",
      fd,
      transformRequest: angular.identity,
      headers: { 'Content-Type': undefined }
    ).then(
      (response)-> # success
        if response.status == 201
          GradeCraftAPI.addItems(fileUploads, "file_uploads", response.data)
        GradeCraftAPI.logResponse(response)

      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )


  # attachments to group grades
  _postGroupFileUploads = (fd)->
    $http.post(
      "/api/assignments/#{grade.assignment_id}/groups/#{_recipientId}/file_uploads",
      fd,
      transformRequest: angular.identity,
      headers: { 'Content-Type': undefined }
    ).then(
      (response)-> # success
        if response.status == 201
          GradeCraftAPI.addItems(fileUploads, "file_uploads", response.data)
        GradeCraftAPI.logResponse(response)

      ,(response)-> # error
        GradeCraftAPI.logResponse(response)
    )

  postFileUploads = (files)->
    fd = new FormData()
    angular.forEach(files, (file, index)->
      fd.append("file_uploads[]", file)
    )
    if _recipientType == "group"
      _postGroupFileUploads(fd)
    else
      _postGradeFileUploads(fd)

  deleteFileUpload = (file)->
    file.deleting = true
    $http.delete("/api/file_uploads/#{file.id}").then(
      (response)-> # success
        if response.status == 200
          GradeCraftAPI.deleteItem(fileUploads, file)
        GradeCraftAPI.logResponse(response)

      ,(response)-> # error
        file.deleting = false
        GradeCraftAPI.logResponse(response)
    )

  return {
    modelGrade: modelGrade
    grades: grades
    fileUploads: fileUploads
    criterionGrades: criterionGrades
    gradeStatusOptions: gradeStatusOptions

    calculateGradePoints: calculateGradePoints

    gradeIsPassing: gradeIsPassing
    setGradeToPass: setGradeToPass
    toggeleGradePassFailStatus: toggeleGradePassFailStatus

    getGrade: getGrade
    queueUpdateGrade: queueUpdateGrade
    submitGrade: submitGrade

    findCriterionGrade: findCriterionGrade
    addCriterionGrade: addCriterionGrade
    setCriterionGradeLevel: setCriterionGradeLevel
    queueUpdateCriterionGrade: queueUpdateCriterionGrade

    postFileUploads: postFileUploads
    deleteFileUpload: deleteFileUpload
  }
]
