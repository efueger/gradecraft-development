@gradecraft.controller 'GradeSchemeElementsCtrl', ['$scope', '$http', 'GradeSchemeElementsService',
  ($scope, $http, GradeSchemeElementsService) ->
    GradeSchemeElementsService.getGradeSchemeElements()

    $scope.gradeService = GradeSchemeElementsService
    $scope.grade_scheme_elements = $scope.gradeService.elements

    $scope.validateElements = (index)->
      console.log "lowest_points: #{$scope.grade_scheme_elements[index].lowest_points}"
      for element, i in $scope.grade_scheme_elements
        $scope.gradeSchemeForm["lowest_points_#{i}"].$setValidity('directConflict', true)
        $scope.gradeSchemeForm["lowest_points_#{i}"].$setValidity('nearConflict', true)
        for otherElement, j in $scope.grade_scheme_elements
          continue if i == j

          if element.lowest_points == otherElement.lowest_points
            # Invalid because it is in direct conflict with another level
            $scope.gradeSchemeForm["lowest_points_#{i}"].$setValidity('directConflict', false)
            $scope.gradeSchemeForm["lowest_points_#{j}"].$setValidity('directConflict', false)

          if (element.lowest_points - 1 == otherElement.lowest_points ||
              element.lowest_points + 1 == otherElement.lowest_points)
            # Invalid because it is within one point of another level
            $scope.gradeSchemeForm["lowest_points_#{i}"].$setValidity('nearConflict', false)
            $scope.gradeSchemeForm["lowest_points_#{j}"].$setValidity('nearConflict', false)
    return
]
