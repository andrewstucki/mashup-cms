module.exports = ->
  link: (scope, element, attrs) ->
    console.log attrs.sparkOptions
    $(element).sparkline('html', angular.fromJson(attrs.sparkOptions))
  restrict: 'E'
  replace: true
  transclude: true
  template: "<span ng-transclude></span>"