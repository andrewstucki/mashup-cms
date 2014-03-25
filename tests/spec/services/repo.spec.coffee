describe "Service: Repo", ->
  $httpBackend = undefined
  $rootScope = undefined
  service = undefined
  restangular = undefined
  repoModel = {id: 17428954, name: "repo", url: "https://repo/url/here", owner: "test", active: false, description: "A fake repo", defaultBranch: "master", createdAt: "2014-03-19T16:08:37.229216Z", updatedAt: "2014-03-19T16:08:37.229216Z"}
  repoModels = [repoModel]
    
  beforeEach ->
    angular.mock.module "restangular"
    
    angular.mock.module ($provide) ->
      $provide.service "repoService", require('services/repo')
      return
    
    inject ($injector) ->
      $httpBackend = $injector.get("$httpBackend")
      
      $rootScope = $injector.get("$rootScope")
      $rootScope.allRepos = repoModels
      
      service = $injector.get "repoService"
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
    
  it "should get the repo by account and name", ->
    $httpBackend.expect("GET", "/repos/test/repo").respond repoModel
    
    response = service.get("test", "repo")
    
    $httpBackend.flush()
    expect(response.originalElement).toEqual repoModel

  it "should get repos by parameters", ->
    $httpBackend.expect("GET", "/repos?owner=test").respond repoModels
    $httpBackend.expect("GET", "/repos").respond repoModels
    
    paramsResponse = service.all({owner: "test"})
    noParamsResponse = service.all()
    $httpBackend.flush()
    expect(paramsResponse.originalElement).toEqual repoModels
    expect(noParamsResponse.originalElement).toEqual repoModels

  it "should be able to toggle repo activation", ->
    $httpBackend.expect("POST", "/repos/test/repo/activate").respond repoModel
    
    service.toggleActivate repoModel
    $httpBackend.flush()
    
    # expect($rootScope.allRepos[0].active).toEqual false
    # expect(repoModel.active).toEqual false
    
    $httpBackend.expect("POST", "/repos/test/repo/activate").respond repoModel
    
    service.toggleActivate repoModel
    $httpBackend.flush()
    # expect($rootScope.allRepos[0].active).toEqual true
    # expect(repoModel.active).toEqual true

  it "should respond to logging the user in", ->
    $httpBackend.expect("GET", "/repos").respond repoModels
    $rootScope.$broadcast("user:loggedIn")
    expect($rootScope.allRepos.originalElement).toEqual undefined
    $httpBackend.flush()
    expect($rootScope.allRepos.originalElement).toEqual repoModels
  
  it "should set an error when activation fails and later clear it", ->
    $httpBackend.expect("POST", "/repos/test/repo/activate").respond 403, "unauthorized"
    
    service.toggleActivate repoModel
    $httpBackend.flush()
    expect(service.activationError).toEqual "There was a problem contacting the server, please try again later."
    service.dismissActivationError()    
    expect(service.activationError).toEqual false