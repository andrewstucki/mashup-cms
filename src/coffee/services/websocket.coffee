class WebsocketService
  @$inject: ['$rootScope']
  
  constructor: (@$rootScope) ->
    @$rootScope.$on "user:loggedIn", (event, data) =>
      @connect(data)
    @$rootScope.$on "user:loggedOut", (event, data) =>
      @close()
      
  setBaseUrl: (url) =>
    @base = url
  
  connect: (token) =>
    @setSocket(new WebSocket("#{@base}?key=#{token}"))
  
  setSocket: (socket) =>
    @websocket = socket
    @websocket.onopen = @onOpen
    @websocket.onmessage = @onMessage
    @websocket.onerror = @onError
    @websocket.onclose = @onClose
  
  close: =>
    if @websocket
      @websocket.close()
  
  onOpen: (message) =>
    console.log "Opened"

  onMessage: (message) =>
    @$rootScope.$emit "websocket:message", JSON.parse(message.data)

  onError: (message) =>
    console.log message.data

  onClose: (message) =>
    console.log "Disconnected"

module.exports = WebsocketService