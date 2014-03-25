window.endpoint = $('meta[rel="mashup.api_endpoint"]').attr('href')
host = window.endpoint.replace /http(s)?\:\/\//g, ""
if window.endpoint.substring(0,4) == "https"
  window.host = "wss://#{host}/stream"
else
  window.host = "ws://#{host}/stream"

githubController = require './controllers/github_controller'
repoController = require './controllers/repo_controller'
repoSettingsController = require './controllers/repo_settings_controller'
userController = require './controllers/user_controller'
profileController = require './controllers/profile_controller'
imageUploadController = require './controllers/image_upload_controller'
videoUploadController = require './controllers/video_upload_controller'
fileUploadController = require './controllers/file_upload_controller'

userService = require './services/user'
repoService = require './services/repo'
githubService = require './services/github'
websocketService = require './services/websocket'
uploadService = require './services/upload'

switchDirective = require './directives/switch'
sparklineDirective = require './directives/sparkline'
codemirrorDirective = require './directives/codemirror'
clndrDirective = require './directives/clndr'

templates = require './templates'

config = ($stateProvider, $urlRouterProvider, $httpProvider, $sceDelegateProvider) ->
  $urlRouterProvider.otherwise('/profile')

  $stateProvider
  .state 'add-github',
    url: '/github'
    templateUrl: 'template/add_github.html'
    controller: ['$scope', 'githubService', ($scope, githubService) -> $scope.add = githubService.add]
  .state 'add-user',
    url: '/user'
    templateUrl: 'template/add_user.html'
    controller: ['$scope', 'userService', ($scope, userService) -> $scope.add = userService.add]
  .state 'profile',
    url: '/profile'
    templateUrl: 'template/profile.html'
    controller: 'profileController'
  .state 'user',
    url: '/user/:name'
    templateUrl: 'template/user.html'
    controller: 'userController'
    resolve: userController.resolve
  .state 'github',
    url: '/github/:account'
    templateUrl: 'template/github.html'
    controller: 'githubController'
    resolve: githubController.resolve
  .state 'repo',
    url: '/:account/:name'
    abstract: true
    views:
      sidebar:
        templateUrl: 'template/repo_sidebar.html'
        controller: 'repoController'
      "":
        templateUrl: 'template/repo.html'
        controller: 'repoController'
    resolve: repoController.resolve
  .state 'repo.posts',
    controller: ['$scope', ($scope) ->
      $scope.time = $.now()
      $scope.content = """
      ## A New Post

      Enter text in [Markdown](http://daringfireball.net/projects/markdown/). Use the toolbar above, or click the **?** button for formatting help.
      """
    ]
    url: '/posts'
    templateUrl: 'template/repo_posts.html'
  .state 'repo.photos',
    controller: 'imageUploadController'
    url: '/photos'
    templateUrl: 'template/repo_photos.html'
  .state 'repo.videos',
    controller: 'videoUploadController'
    url: '/videos'
    templateUrl: 'template/repo_videos.html'
  .state 'repo.attachments',
    controller: 'fileUploadController'
    url: '/attachments'
    templateUrl: 'template/repo_attachments.html'
  .state 'repo.calendar',
    url: '/calendar'
    templateUrl: 'template/repo_calendar.html'

  $sceDelegateProvider.resourceUrlWhitelist(['self', window.endpoint+'/**'])

setup = ($rootScope, $state, $stateParams, $window, $http, Restangular, websocketService, userService, githubService, repoService, uploadService) ->
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
  $rootScope.login = userService.login
  $rootScope.logout = userService.logout

  Restangular.setBaseUrl $window.endpoint
  Restangular.setDefaultHeaders {'Content-Type': 'application/json'}
  Restangular.setResponseExtractor (response) ->
    newResponse = response
    if angular.isArray(response)
      newResponse.originalElement = new Array(response.length)
      angular.forEach newResponse, (value, key) ->
        newResponse.originalElement[key] = angular.copy(value)
    else
      newResponse.originalElement = angular.copy(response)
    newResponse
  
  uploadService.setUrl "#{$window.endpoint}/upload"
  websocketService.setBaseUrl $window.host
  if $window.user
    $http.defaults.headers.common['X-Mashup-Key'] = $window.apiKey
    $rootScope.loggedIn = true
    $rootScope.currentUser = $window.user
    $rootScope.allAccounts = githubService.all()
    $rootScope.allRepos = repoService.all()
    $rootScope.allUsers = userService.all()
  if $window.socketConnection
    websocketService.setSocket $window.socketConnection

angular.element(document).ready () ->
  initialize = () ->
    app = angular.module 'angularApp', ['ui.router', 'ui.select2', 'ui.bootstrap.modal', 'ngCookies', 'restangular', 'blueimp.fileupload']
    
    app.service 'websocketService', websocketService
    app.service 'userService', userService

    app.service 'repoService', repoService
    app.service 'githubService', githubService
    app.service 'uploadService', uploadService

    app.controller 'userController', userController
    app.controller 'githubController', githubController
    app.controller 'repoController', repoController
    app.controller 'repoSettingsController', repoSettingsController
    app.controller 'profileController', profileController
    app.controller 'imageUploadController', imageUploadController
    app.controller 'videoUploadController', videoUploadController
    app.controller 'fileUploadController', fileUploadController

    app.directive 'switch', switchDirective
    app.directive 'sparkline', sparklineDirective
    app.directive 'codemirror', codemirrorDirective
    app.directive 'clndr', clndrDirective
    
    app.config ['$stateProvider','$urlRouterProvider', '$httpProvider', '$sceDelegateProvider', config]

    app.run templates
    app.run [ '$rootScope', '$state', '$stateParams', '$window', '$http', 'Restangular', 'websocketService', 'userService', 'githubService', 'repoService', 'uploadService', setup]
    
    angular.bootstrap(document, ['angularApp'])

  # try to log the user in before angular is ever hit
  apiKey = $.cookie("apiKey")
  if apiKey
    $.ajax(
      url: "#{window.endpoint}/auth/user"
      type: "GET"
      beforeSend: (xhr) ->
        xhr.setRequestHeader 'X-Mashup-Key', apiKey
      success: (data) ->
        window.user = data
        window.apiKey = apiKey
        try
          window.socketConnection = new WebSocket("#{window.host}?key=#{apiKey}")
        catch error
          console.log(error)
    ).always initialize
  else
    initialize()

$(window).load () ->
  $('.loader').hide()
  $('.content').show()