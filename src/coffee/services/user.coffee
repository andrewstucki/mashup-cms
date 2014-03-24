class UserService
  @$inject: ['$rootScope', '$http', '$cookies', 'Restangular']
  
  constructor: (@$rootScope, @$http, @$cookies, @Restangular) ->
    @loginError = false
    @Restangular.addElementTransformer 'auth', true, (auth) =>
      auth.addRestangularMethod('login', 'post', 'login')
      auth.addRestangularMethod('user', 'get', 'user')
      auth

  login: (username, password) =>
    @Restangular.all('auth').login(
      username: username
      password: password
    ).then ((response) =>
        @$cookies.apiKey = response.token
        @$http.defaults.headers.common['X-Mashup-Key'] = response.token
        @$rootScope.loggedIn = true
        @current (response) =>
          @$rootScope.currentUser = response
        @$rootScope.allUsers = @all()
        @$rootScope.$emit "user:loggedIn", response.token
    ), (response) =>
      @loginError = "That username and password could not be matched with an existing account."
  
  logout: =>
    @$rootScope.loggedIn = false
    delete @$rootScope.currentUser
    delete @$cookies.apiKey
    delete @$http.defaults.headers.common['X-Mashup-Key']
    @$rootScope.$emit "user:loggedOut"
  
  get: (name) =>
    @Restangular.one('users', name).get().$object
    
  all: (params) =>
    @Restangular.all('users').getList(params).$object
  
  current: =>
    if @$rootScope.currentUser
      success?(@$rootScope.currentUser)
    else
      promise = @Restangular.all('auth').user()
      promise.then (response) =>
        @$rootScope.currentUser = response
      promise.$object

  add: (name, password, confirm) =>
    @Restangular.all('users').post(
      login: name
      password: password
    )
    
  dismissLoginError: =>
    @loginError = false
    
module.exports = UserService