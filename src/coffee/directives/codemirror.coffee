module.exports = ->
  restrict: "EA"
  require: "?ngModel"
  priority: 1
  compile: compile = (tElement) ->
    # Create a codemirror instance with
    # - the function that will to place the editor into the document.
    # - the initial content of the editor.
    #   see http://codemirror.net/doc/manual.html#api_constructor
    value = tElement.text()
    codeMirror = new window.CodeMirror((cm_el) ->
      angular.forEach tElement.prop("attributes"), (a) ->
        if a.name is "codemirror"
          cm_el.setAttribute "codemirror-opts", a.textContent
        else
          cm_el.setAttribute a.name, a.textContent
        return

      
      # FIX replaceWith throw not parent Error !
      tElement.wrap "<div>"  if tElement.parent().length <= 0
      tElement.replaceWith cm_el
      return
    ,
      value: value
    )
    postLink = (scope, iElement, iAttrs, ngModel) ->
      updateOptions = (newValues) ->
        for key of newValues
          codeMirror.setOption key, newValues[key]  if newValues.hasOwnProperty(key)
        return
      options = undefined
      opts = undefined
      options = {}
      opts = angular.extend({}, options, scope.$eval(iAttrs.codemirror), scope.$eval(iAttrs.codemirrorOpts))
      updateOptions opts
      scope.$watch iAttrs.codemirror, updateOptions, true  if angular.isDefined(scope.$eval(iAttrs.codemirror))
      
      # Specialize change event
      codeMirror.on "change", (instance) ->
        newValue = instance.getValue()
        ngModel.$setViewValue newValue  if ngModel and newValue isnt ngModel.$viewValue
        scope.$apply()  unless scope.$$phase
        return

      if ngModel
        
        # CodeMirror expects a string, so make sure it gets one.
        # This does not change the model.
        ngModel.$formatters.push (value) ->
          if angular.isUndefined(value) or value is null
            return ""
          else throw new Error("codemirror cannot use an object or an array as a model")  if angular.isObject(value) or angular.isArray(value)
          value

        
        # Override the ngModelController $render method, which is what gets called when the model is updated.
        # This takes care of the synchronizing the codeMirror element with the underlying model, in the case that it is changed by something else.
        ngModel.$render = ->
          
          #Code mirror expects a string so make sure it gets one
          #Although the formatter have already done this, it can be possible that another formatter returns undefined (for example the required directive)
          safeViewValue = ngModel.$viewValue or ""
          codeMirror.setValue safeViewValue
          return
      
      # Watch ui-refresh and refresh the directive
      if iAttrs.uiRefresh
        scope.$watch iAttrs.uiRefresh, (newVal, oldVal) ->
          
          # Skip the initial watch firing
          codeMirror.refresh()  if newVal isnt oldVal
          return

      
      # onLoad callback
      opts.onLoad codeMirror  if angular.isFunction(opts.onLoad)