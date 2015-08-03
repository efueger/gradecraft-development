@gradecraft = angular.module('gradecraft', ['restangular', 'ui.slider', 'ui.sortable', 'ng-rails-csrf', 'ngResource', 'ngAnimate', 'templates', 'formly', 'formlyFoundation'])

INTEGER_REGEXP = /^\-?\d+$/
@gradecraft.directive "integer", ->
  require: "ngModel"
  link: (scope, elm, attrs, ctrl) ->
    ctrl.$parsers.unshift (viewValue) ->
      if INTEGER_REGEXP.test(viewValue)
        # it is valid
        ctrl.$setValidity "integer", true
        viewValue
      else
        # it is invalid, return undefined (no model update)
        ctrl.$setValidity "integer", false
        'undefined'
    return

@gradecraft.directive "collapseToggler", ->
  restrict : 'C',
  link: (scope, elm, attrs) ->
    elm.bind('click', ()->
      elm.siblings().toggleClass('collapsed')
    )
    return

#formly config

@gradecraft.constant('apiCheck', apiCheck());

@gradecraft.run((formlyConfig, apiCheck) ->
  formlyConfig.setWrapper({
    name: 'gradeInputInvalid',
    templateUrl: 'ng_gradeInputWrapper.html'
  })
  formlyConfig.setType({
    name: 'gradeScheme',
    templateUrl: 'ng_gradeScheme.html',
    controller: ($scope) ->
      $scope.formOptions = {formState: $scope.formState}
      $scope.addNew = () ->
        $scope.model[$scope.options.key] = $scope.model[$scope.options.key] || []
        repeatsection = $scope.model[$scope.options.key]
        lastSection = repeatsection[repeatsection.length - 1]
        newsection = {}
        # if (lastSection)
        #   newsection = angular.copy(lastSection)
        repeatsection.push(newsection)

      $scope.remove = (sections, $index) ->
        sections.splice($index, 1)

      $scope.copyFields = (fields) ->
        angular.copy(fields)
  })
)
