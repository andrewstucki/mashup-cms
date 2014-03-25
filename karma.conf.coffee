module.exports = (config) ->
  config.set
    frameworks: ["jasmine"]
    exclude: []
    reporters: ["progress"]
    port: 9876
    runnerPort: 9100
    colors: true
    autoWatch: true
    captureTimeout: 60000
    singleRun: false