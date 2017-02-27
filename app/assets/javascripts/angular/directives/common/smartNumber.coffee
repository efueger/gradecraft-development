@gradecraft.directive 'smartNumber', ['$filter', ($filter) ->
  return {
    scope: {
      allowNegatives: "="
      allowNull: '='
    }
    require: 'ngModel',
    link: (scope, element, attrs, modelCtrl)->
      modelCtrl.$parsers.push((inputValue)->
        inputValue = inputValue.replace(/-/g, '') unless scope.allowNegatives
        inputValue = inputValue.replace(/[^\d-]/g, '')
          .replace(/^(-)0/g, '$1')

        if inputValue == '-' || inputValue == '0-'
          modelCtrl.$setViewValue('-')
          inputValue = 0
        else if inputValue == ''
          modelCtrl.$setViewValue('')
          inputValue = if scope.allowNull then null else 0
        else
          modelCtrl.$setViewValue($filter('number')(inputValue))

        modelCtrl.$render()
        return parseInt(inputValue)
      )

      modelCtrl.$formatters.push((inputValue)->
        # debugger
        defaultValue = if scope.allowNull then null else 0
        return defaultValue if isNaN(inputValue)
        return $filter('number')(inputValue)
      )
  }
]
