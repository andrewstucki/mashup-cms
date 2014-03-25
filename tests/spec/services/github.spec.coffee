describe "Service: Github", ->
  $httpBackend = undefined
  $rootScope = undefined
  service = undefined
  restangular = undefined
  accountModel = {id: 3577250, login: "test", isSyncing: false, syncedAt: "2014-03-21T03:50:25.23169Z", gravatarId: "6ba1bdfa6ba08225903a74383be42b06", createdAt: "2014-03-19T16:08:35.254555Z", updatedAt: "2014-03-21T03:50:25.2317Z"}
  accountModels = [accountModel]
  syncResponse = {taskId: "L8JjDO0JFVQ5sT4BrqKycg", type: "githubAccountSync"}
  userModel = {id: 1, name: "test", email: "test@test.com", login: "test"}
  userModels = [userModel]
    
  beforeEach ->
    angular.mock.module "restangular"
    
    angular.mock.module ($provide) ->
      $provide.service "githubService", require('services/github')
      return
    
    inject ($injector) ->
      $httpBackend = $injector.get("$httpBackend")
      
      $rootScope = $injector.get("$rootScope")
      $rootScope.allAccounts = accountModels
      
      service = $injector.get "githubService"
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
    
  it "should be able to add accounts", ->
    # add: (token) =>
    #   @Restangular.one('githubAccounts').token(
    #     githubToken: token
    #   ).then ((response) =>
    #       @$rootScope.allAccounts.push response
    #       @$rootScope.$state.transitionTo 'github', {account: response.login}
    #   ), (response) =>
    #     console.log response

  it "should get accounts by name", ->
    $httpBackend.expect("GET", "/githubAccounts/test").respond accountModel    
    response = service.get("test")
    $httpBackend.flush()
    expect(response.originalElement).toEqual accountModel
  
  it "should get all accounts by parameters", ->
    $httpBackend.expect("GET", "/githubAccounts").respond accountModels   
    $httpBackend.expect("GET", "/githubAccounts?login=test").respond accountModels
    noParamsResponse = service.all()
    paramsResponse = service.all({login: "test"})
    $httpBackend.flush()
    expect(noParamsResponse.originalElement).toEqual accountModels
    expect(paramsResponse.originalElement).toEqual accountModels

  it "should get all administrators", ->
    $httpBackend.expect("GET", "/githubAccounts/test/admins").respond userModels    
    response = service.admins("test").$object
    $httpBackend.flush()
    expect(response.originalElement).toEqual userModels

  it "should respond to logging the user in", ->
    $httpBackend.expect("GET", "/githubAccounts").respond accountModels
    $rootScope.$broadcast("user:loggedIn")
    expect($rootScope.allAccounts.originalElement).toEqual undefined
    $httpBackend.flush()
    expect($rootScope.allAccounts.originalElement).toEqual accountModels
      
  it "should update administrators", ->
    # updateAdmins: (accountName, added, removed) =>
    #   if added.length > 0
    #     @Restangular.one('githubAccounts', accountName).all('admins').post added
    #   if removed.length > 0
    #     @Restangular.one('githubAccounts', accountName).customOperation 'remove', 'admins', undefined, undefined, removed

  it "should sync accounts", ->
    $httpBackend.expect("POST", "/githubAccounts/test/sync").respond syncResponse
    response = service.sync("test")
    $httpBackend.flush()
    expect(response.originalElement).toEqual syncResponse