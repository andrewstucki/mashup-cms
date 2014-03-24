module.exports = ['$parse', ($parse) ->
  link: (scope, element, attrs) =>
    @triggered = false
    @disabled = false
    onChange = $parse(attrs.onToggle)
    attrs.$observe 'isChecked', (val) =>
      if val is "true"
        $(element).attr("checked", "checked")
      if not $(element).parent().parent().hasClass("switch")
        $(element).wrap('<div class="switch" />').parent().bootstrapSwitch()
    $(element).on 'change', (event) =>
      if @triggered
        @triggered = false
        return
      if @disabled
        event.stopImmediatePropagation()
        event.preventDefault()
        return
      @disabled = true
      event.stopImmediatePropagation()
      event.preventDefault()
      scope.$apply =>
        onChange scope,
          callback: =>
            @disabled = false
            @triggered = true
            $(element).trigger("change")
          error: =>
            @disabled = false

  restrict: 'E'
  replace: true
  template: "<input type='checkbox' data-toggle='switch'>"
]