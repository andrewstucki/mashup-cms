class RepoSettingsController
  @$inject: ['$scope', '$modalInstance', 'repo']

  constructor: (@$scope, @$modalInstance, repo) ->
    @$scope.repo = repo
    @$scope.save = @save
    @$scope.cancel = @cancel
  
  save: =>
    @$modalInstance.close()
    
  cancel: =>
    @$modalInstance.dismiss('cancel')

module.exports = RepoSettingsController