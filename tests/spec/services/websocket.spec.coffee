describe "Service: Websocket", ->
  $rootScope = undefined
  service = undefined
  mockSocket = {tracking: "123"}
  mockSocket.close = jasmine.createSpy "socket close"

  beforeEach ->
    angular.mock.module ($provide) ->
      $provide.service "websocketService", require('services/websocket')
      return
    
    inject ($injector) ->
      $rootScope = $injector.get("$rootScope")
      spyOn($rootScope, "$emit")
      service = $injector.get "websocketService"
    return

  it "should set a base url", ->
    expect(service.base).toEqual undefined
    service.setBaseUrl "http://google.com"
    expect(service.base).toEqual "http://google.com"
    
  it "should set a new websocket", ->
    expect(service.websocket).toEqual undefined
    service.setSocket mockSocket
    expect(service.websocket.tracking).toEqual mockSocket.tracking
    expect(service.websocket.onopen).toEqual service.onOpen  
    expect(service.websocket.onmessage).toEqual service.onMessage
    expect(service.websocket.onerror).toEqual service.onError
    expect(service.websocket.onclose).toEqual service.onClose
  
  it "should close sockets", ->
    service.setSocket mockSocket
    $rootScope.$broadcast("user:loggedOut")
    expect(mockSocket.close).toHaveBeenCalled()
  
  it "should emit messages", ->
    service.onMessage({data: '{"secret":"this is a test"}'})
    expect($rootScope.$emit).toHaveBeenCalledWith("websocket:message", {secret: "this is a test"})