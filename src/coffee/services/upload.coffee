class UploadService  
  constructor: ->
    @imageBackend = "flickr"
    @videoBackend = "vimeo"
    @fileBackend = "s3"
    
  setUrl: (url) =>
    @url = url

module.exports = UploadService