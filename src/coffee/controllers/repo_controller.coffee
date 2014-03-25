class RepoController
  @$inject: ['$scope', '$rootScope', '$modal', 'repoService', 'repo']
  @resolve:
    repo: ['$stateParams', 'repoService', (params, repoService) -> repoService.get params.account, params.name ]

  constructor: (@$scope, @$rootScope, @$modal, @repoService, repo, name) ->
    @$scope.repo = repo
    @$scope.settings = @settings
    @$scope.name = "#{@$rootScope.$stateParams.account}/#{@$rootScope.$stateParams.name}"
  
  settings: =>
    modal = @$modal.open
      templateUrl: "template/repo_settings.html"
      controller: "repoSettingsController"
      resolve:
        repo: =>
          @$scope.repo

    modal.result.then (form) =>
      console.log form

module.exports = RepoController