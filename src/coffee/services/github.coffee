class GithubAccountService
  @$inject: ['$rootScope', 'Restangular']
  
  constructor: (@$rootScope, @Restangular) ->
    @Restangular.addElementTransformer 'githubAccounts', false, (githubAccount) =>
      githubAccount.addRestangularMethod('token', 'post', 'token')
      githubAccount.addRestangularMethod('sync', 'post', 'sync')
      githubAccount

    @$rootScope.$on "user:loggedIn", =>
      @$rootScope.allAccounts = @all()
  
  add: (token) =>
    @Restangular.one('githubAccounts').token(
      githubToken: token
    ).then ((response) =>
        @$rootScope.allAccounts.push response
        @$rootScope.$state.transitionTo 'github', {account: response.login}
    ), (response) =>
      console.log response
  
  admins: (accountName) =>
    @Restangular.one('githubAccounts', accountName).all('admins').getList()
    
  updateAdmins: (accountName, added, removed) =>
    if added.length > 0
      @Restangular.one('githubAccounts', accountName).all('admins').post added
    if removed.length > 0
      @Restangular.one('githubAccounts', accountName).customOperation 'remove', 'admins', undefined, undefined, removed

  get: (accountName) =>
    @Restangular.all('githubAccounts').get(accountName).$object

  all: (params) =>
    @Restangular.all('githubAccounts').getList(params).$object

  sync: (accountName) =>
    @Restangular.one('githubAccounts', accountName).sync().$object

module.exports = GithubAccountService