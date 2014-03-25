describe "Service: Upload", ->
  service = undefined
  beforeEach ->
    angular.mock.module ($provide) ->
      $provide.service "uploadService", require('services/upload')
      return
    
    inject ($injector) ->
      service = $injector.get "uploadService"
    return

  it "should set default backends", ->
    expect(service.imageBackend).toEqual "flickr"
    expect(service.videoBackend).toEqual "vimeo"
    expect(service.fileBackend).toEqual "s3"
  
  it "should be able to change the url", ->
    expect(service.url).toEqual undefined
    service.setUrl("http://google.com")
    expect(service.url).toEqual "http://google.com"