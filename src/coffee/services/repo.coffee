class RepoService
  @$inject: ['$rootScope', 'Restangular']
  
  constructor: (@$rootScope, @Restangular) ->
    @scope = @$rootScope
    @$rootScope.$on "user:loggedIn", =>
      @$rootScope.allRepos = @all()
  
  get: (account, name) =>
    @Restangular.one('repos', account).one(name).get().$object
  
  all: (params) =>
    @Restangular.all('repos').getList(params).$object
  
  toggleActivate: (repo, callback, error) =>
    @Restangular.one('repos', repo.owner).one(repo.name, 'activate').post().then ((response) => #ghetto
      for _repo, index in @$rootScope.allRepos
        if _repo.id is repo.id
          @$rootScope.allRepos[index].active = !repo.active
          repo.active = !repo.active
      callback?()
    ), (response) =>
      @activationError = "There was a problem contacting the server, please try again later."
      error?()

  dismissActivationError: () =>
    @activationError = false

module.exports = RepoService