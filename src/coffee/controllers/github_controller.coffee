class GithubController
  
  @$inject: ['$scope', '$rootScope', 'repoService', 'githubService', 'repos', 'account', 'admins']
  @resolve:
    repos: ['$stateParams', 'repoService', (params, repoService) -> repoService.all {owner: params.account} ]
    account: ['$stateParams', 'githubService', (params, githubService) -> githubService.get params.account ]
    admins: ['$stateParams', 'githubService', (params, githubService) -> githubService.admins params.account ]
    
  constructor: (@$scope, @$rootScope, @repoService, @githubService, repos, account, admins) ->
    @$scope.repos = repos
    @$scope.account = account
    @$scope.repoService = @repoService
    @$scope.sync = @sync
    @$scope.githubService = @githubService
    @$scope.lastSynced = @timeAgoInWords
    @$scope.admins = admins
    @$scope.adminNames = _.filter(
      _.map(admins, (admin) =>
        admin.login
      ),
      (admin) =>
        admin
    )
    
    @$scope.adminOptions =
      multiple: true
  
    @$scope.$watch(
      'adminNames',
      ((newAdmins, oldAdmins) =>
        added = _.difference newAdmins, oldAdmins
        removed = _.difference oldAdmins, newAdmins
        addedAdmins = _.filter @$rootScope.allUsers.originalElement, (admin) =>
          admin.login in added
        removedAdmins = _.filter @$rootScope.allUsers.originalElement, (admin) =>
          admin.login in removed
        @githubService.updateAdmins(account.login, addedAdmins, removedAdmins)
      ), true
    )
    
    @$rootScope.$on "websocket:message", (event, data) =>
      console.log data
      console.log @task
      if data.taskId and data.taskId is @task.taskId and data.status is "done"
        @$scope.account = @githubService.get account.login
        @$rootScope.allRepos = @repoService.all()
        @$scope.repos = @repoService.all {owner: account.login}
        
  sync: (accountName) =>
    @$scope.account.isSyncing = true
    @task = @githubService.sync accountName
    
  timeAgoInWords: (date) =>
    if typeof date is 'string'
      date = $.timeago.parse(date)
    distance = $.now() - date.getTime()
    $.timeago.inWords(distance)
      
module.exports = GithubController