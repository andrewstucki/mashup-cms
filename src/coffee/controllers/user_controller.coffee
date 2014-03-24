class UserController
  @$inject: ['$scope', 'userService', 'user']
  @resolve:
    user: ['$stateParams', 'userService', (params, userService) -> userService.get params.name ]
  
  constructor: (@$scope, @userService, user) ->
    @$scope.user = user

module.exports = UserController