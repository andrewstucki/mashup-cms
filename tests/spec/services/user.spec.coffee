describe "Service: User", ->
  $httpBackend = undefined
  $rootScope = undefined
  $http = undefined
  $cookies = undefined
  service = undefined
  restangular = undefined
  userModel = {id: 1, name: "test", email: "test@test.com", login: "test"}
  userModels = [userModel]
  tokenModel = {token: "abcdefghijklmnopqrstuvwxyz"}
    
  beforeEach ->
    angular.mock.module "restangular"
    
    angular.mock.module ($provide) ->
      $provide.value "$cookies", {}
      $provide.service "userService", require('services/user')
      return
    
    inject ($injector) ->
      $httpBackend = $injector.get("$httpBackend")
      $rootScope = $injector.get("$rootScope")
      spyOn($rootScope, "$emit")
      
      $http = $injector.get("$http")
      $cookies= $injector.get("$cookies")
      service = $injector.get "userService"
      restangular = $injector.get "Restangular"
      restangular.setResponseExtractor (response) ->
        newResponse = response
        if angular.isArray(response)
          newResponse.originalElement = new Array(response.length)
          angular.forEach newResponse, (value, key) ->
            newResponse.originalElement[key] = angular.copy(value)
        else
          newResponse.originalElement = angular.copy(response)
        newResponse
    return

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it "should set headers and current user scope on login", ->
    $httpBackend.expect("POST", "/auth/login").respond tokenModel
    $httpBackend.expect("GET", "/auth/user").respond userModel
    $httpBackend.expect("GET", "/users").respond userModels    
    service.login("test", "123")
    $httpBackend.flush()
    
    expect($cookies.apiKey).toEqual tokenModel.token
    expect($http.defaults.headers.common['X-Mashup-Key']).toEqual tokenModel.token
    expect($rootScope.loggedIn).toEqual true
    expect($rootScope.currentUser.originalElement).toEqual userModel
    expect($rootScope.allUsers.originalElement).toEqual userModels
    expect($rootScope.$emit).toHaveBeenCalledWith("user:loggedIn", tokenModel.token)

  it "should remove headers and current user scope on logout", ->
    $httpBackend.expect("POST", "/auth/login").respond tokenModel
    $httpBackend.expect("GET", "/auth/user").respond userModel
    $httpBackend.expect("GET", "/users").respond userModels
    service.login("test", "123")
    $httpBackend.flush()

    service.logout()
    expect($rootScope.loggedIn).toEqual false
    expect($rootScope.currentUser).toEqual undefined
    expect($cookies.apiKey).toEqual undefined
    expect($http.defaults.headers.common['X-Mashup-Key']).toEqual undefined
    expect($rootScope.$emit).toHaveBeenCalledWith("user:loggedOut")

  it "should set a login error value on a failed login and later clear the error", ->
    $httpBackend.expect("POST", "/auth/login").respond 403, 'unauthorized'
    service.login("test", "123")
    $httpBackend.flush()
    
    expect(service.loginError).toEqual "That username and password could not be matched with an existing account."
    service.dismissLoginError()
    expect(service.loginError).toEqual false
    
  it "should get the user by name", ->
    $httpBackend.expect("GET", "/users/test").respond userModel
    
    response = service.get("test")
    
    $httpBackend.flush()
    expect(response.originalElement).toEqual userModel  

  it "should get users by parameters", ->
    $httpBackend.expect("GET", "/users?name=test").respond userModels
    $httpBackend.expect("GET", "/users").respond userModels
    
    paramsResponse = service.all({name: "test"})
    noParamsResponse = service.all()
    $httpBackend.flush()
    expect(paramsResponse.originalElement).toEqual userModels
    expect(noParamsResponse.originalElement).toEqual userModels
    