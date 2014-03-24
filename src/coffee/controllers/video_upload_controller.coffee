class VideoUploadController
  
  @$inject: ['$scope', '$rootScope', '$http', 'uploadService']
  constructor: (@$scope, @$rootScope, @$http, @uploadService) ->
    @$scope.options = 
      url: @uploadService.url
      headers: _.extend({"X-Backend": @uploadService.videoBackend, "X-Repo-Id": @$scope.name}, $http.defaults.headers.common)
    @$scope.loadingFiles = false
    @$scope.destroy = @destroy
    @$scope.cancel = @cancel
  
  destroy: (file) =>
    file.state = "pending"
    @$http(
      url: file.deleteUrl
      method: file.deleteType
    ).then (=>
      file.state = "resolved"
      @$scope.clear file
    ), =>
      file.state = "rejected"

  cancel: (file) =>
    @$scope.clear file

module.exports = VideoUploadController