module.exports = (grunt) ->
  
  # show elapsed time at the end
  require("time-grunt") grunt
  
  # load all grunt tasks
  require("load-grunt-tasks") grunt
  
  config =
    source: "src"
    test: "tests"
    build: ".tmp" 
    output: "public"

  sources =
    vendor: [
      "<%= bower.directory %>/lodash/dist/lodash.min.js"
      "<%= bower.directory %>/jquery/dist/jquery.min.js"
      "<%= bower.directory %>/jquery-cookie/jquery.cookie.js"
      "<%= bower.directory %>/jquery-timeago/jquery.timeago.js"
      "<%= bower.directory %>/select2/select2.min.js"          
      "<%= bower.directory %>/bootstrap/dist/js/bootstrap.min.js"
      "<%= bower.directory %>/angular/angular.min.js"
      "<%= bower.directory %>/angular-cookies/angular-cookies.min.js"
      "<%= bower.directory %>/angular-ui-router/release/angular-ui-router.min.js"
      "<%= bower.directory %>/angular-ui-bootstrap/src/transition/transition.js"
      "<%= bower.directory %>/angular-ui-bootstrap/src/modal/modal.js"
      "<%= bower.directory %>/angular-ui-select2/src/select2.js"
      "<%= bower.directory %>/restangular/dist/restangular.min.js"
      "<%= bower.directory %>/codemirror/lib/codemirror.js"
      "<%= bower.directory %>/codemirror/mode/markdown/markdown.js"
      "<%= bower.directory %>/marked/lib/marked.js"
      "<%= bower.directory %>/clndr/clndr.min.js"
      "<%= bower.directory %>/moment/min/moment.min.js"

      "<%= bower.directory %>/blueimp-file-upload/js/vendor/jquery.ui.widget.js"
      "<%= bower.directory %>/blueimp-load-image/js/load-image.min.js"
      "<%= bower.directory %>/blueimp-canvas-to-blob/js/canvas-to-blob.min.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.iframe-transport.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload-process.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload-image.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload-video.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload-validate.js"
      "<%= bower.directory %>/blueimp-file-upload/js/jquery.fileupload-angular.js"        

      "<%= application.source %>/js/jquery-ui-1.10.3.custom.min.js"
      "<%= application.source %>/js/jquery.ui.touch-punch.min.js"
      "<%= application.source %>/js/sparkline.js"
      "<%= application.source %>/js/bootstrap-select.js"
      "<%= application.source %>/js/bootstrap-switch.js"
      "<%= application.source %>/js/flatui-checkbox.js"
      "<%= application.source %>/js/flatui-radio.js"
      "<%= application.source %>/js/flatui-fileinput.js"
      "<%= application.source %>/js/jquery.placeholder.js"
      "<%= application.source %>/js/typeahead.js"
    ]  

  grunt.initConfig
    application: config
    bower: grunt.file.readJSON('.bowerrc')
        
    watch:
      templates:
        files: "<%= application.source %>/pages/**/*.jade"
        tasks: ["jade:templates"]

      coffee:
        files: ["<%= application.source %>/coffee/**/*.coffee"]
        tasks: ["coffee:build"]

      test:
        files: ["<%= application.test %>/spec/{,*/}*.coffee"]
        tasks: ["coffee:test"]

      less:
        files: ["<%= application.source %>/less/**/*.less"]
        tasks: ["less"]

      scripts:
        files: ["<%= application.build %>/scripts/**/*.js", "!<%= build %>/scripts/combined-application.js"]
        tasks: ["scripts:browserify", "scripts:concat"]

    clean:
      build:
        files: [
          dot: true
          src: ["<%= application.build %>", "<%= application.output %>/*", "!<%= application.output %>/.git*"]
        ]

    coffee:
      build:
        files: [
          expand: true
          cwd: "<%= application.source %>/coffee"
          src: "**/*.coffee"
          dest: "<%= application.build %>/scripts"
          ext: ".js"
        ]

      test:
        files: [
          expand: true
          cwd: "<%= application.test %>"
          src: "**/*.coffee"
          dest: "<%= application.build %>/tests"
          ext: ".js"
        ]
      
      karma:
        files:
          "<%= application.build %>/karma.conf.js": "karma.conf.coffee"

    less:
      build:
        options:
          paths: ["<%= bower.directory %>", "<%= application.source %>/less" ]
          cleancss: true
          ieCompat: false
        files:
          "<%= application.output %>/application.css": "<%= application.source %>/less/application.less"

    imagemin:
      dist:
        files: [
          expand: true
          cwd: "<%= application.build %>/images"
          src: "**/*.{png,jpg,jpeg}"
          dest: "<%= application.build %>/images"
        ]

    svgmin:
      dist:
        files: [
          expand: true
          cwd: "<%= application.build %>/images"
          src: "**/*.svg"
          dest: "<%= application.build %>/images"
        ]
    
    # Put files not handled in other tasks here
    copy:
      build:
        files: [
          expand: true
          dot: true
          cwd: "<%= application.source %>"
          dest: "<%= application.output %>"
          src: ["*.ico", "images/**/*.{webp,gif,png,jpg,jpeg,svg}", "fonts/**/*"]
        ]

    uglify:
      options:
        mangle: false
      scripts:
        files:
          "<%= application.output %>/application.js": ["<%= application.output %>/application.js"]

    jade:
      pages:
        files: [
          expand: true
          cwd: "<%= application.source %>/pages"
          src: ["*.jade"]
          dest: "<%= application.output %>"
          ext: ".html"
        ]
      templates:
        files: [
          expand: true
          cwd: "<%= application.source %>/template"
          src: ["**/*.jade"]
          dest: "<%= application.build %>/template"
          ext: ".html"
        ]

    concurrent:
      build: ["jade", "coffee:build", "less", "copy:build"]
      test: ["coffee"]

    browserify:
      build:
        src: ["<%= application.build %>/scripts/application.js"]
        dest: "<%= application.build %>/scripts/combined-application.js"
      tests:
        src: ["<%= application.build %>/tests/tests.js"]
        dest: "<%= application.build %>/tests/all-tests.js"
        options:
          aliasMappings:
            cwd: "<%= application.build %>/scripts",
            src: ['**/*.js']

    concat:
      scripts:
        src: sources.vendor.concat ["<%= application.build %>/scripts/combined-application.js"]
        dest: "<%= application.output %>/application.js"
      
    ngtemplates:
      build:
        cwd: "<%= application.build %>"
        src: "template/**/*.html"
        dest: "<%= application.build %>/scripts/templates.js"
        options:
          bootstrap: (module, script) ->
            return '(function() {module.exports = ["$templateCache", function($templateCache) {'+script+'}];}).call(this);'
    
    karma:
      options:
        files: sources.vendor.concat [
          "<%= bower.directory %>/angular-mocks/angular-mocks.js"
          "<%= application.build %>/tests/all-tests.js"
        ]
        basePath: __dirname
      continuous:
        configFile: '<%= application.build %>/karma.conf.js',
        singleRun: true,
        browsers: ['PhantomJS']
        

  grunt.registerTask "test", [
    "clean"
    "concurrent:test"
    "ngtemplates"
    "browserify"
    "concat"
    "karma"
  ]
  
  grunt.registerTask "build", [
    "clean:build",
    "concurrent:build",
    "ngtemplates",
    "browserify",
    "concat:scripts",
    "uglify"
  ]
  
  grunt.registerTask "default", ["build"]
