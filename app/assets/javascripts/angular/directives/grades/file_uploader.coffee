# Handles uploading files attached to grades

@gradecraft.directive 'gradeFileUploader', ['$parse', 'GradeService', ($parse, GradeService) ->
  UploadCtrl = [()->
    vm = this
    vm.fileUploads = GradeService.fileUploads

    vm.deleteFile = (file)->
      GradeService.deleteFileUpload(file)
  ]

  {
    bindToController: true,
    controller: UploadCtrl,
    controllerAs: 'vm',
    scope: {},
    templateUrl: 'grades/file_uploads.html'
  }
]

# adapted from https://uncorkedstudios.com/blog/multipartformdata-file-upload-with-angularjs
@gradecraft.directive('fileUpload', ['$parse', 'GradeService', ($parse, GradeService)->
  return {
    restrict: 'A',
    link: (scope, element, attrs)->
      model = $parse(attrs.fileUpload)

      element.bind('change', ()->
        scope.$apply(()->
          model.assign(scope, element[0].files)
          GradeService.postFileUploads(element[0].files)
        )
      )
    }
])
