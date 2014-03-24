module.exports = ->
  currentMonth = moment().format('YYYY-MM')
  nextMonth    = moment().add('month', 1).format('YYYY-MM')

  events = [
    { date: currentMonth + '-' + '10', title: 'Persian Kitten Auction', location: 'Center for Beautiful Cats' },
    { date: currentMonth + '-' + '19', title: 'Cat Frisbee', location: 'Jefferson Park' },
    { date: currentMonth + '-' + '23', title: 'Kitten Demonstration', location: 'Center for Beautiful Cats' },
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session Small Cat Photo Session Small Cat Photo Session Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { date: nextMonth + '-' + '07',    title: 'Small Cat Photo Session', location: 'Center for Cat Photography' }
    { startDate: moment().subtract('months', 3).format('YYYY-MM-') + '12', endDate: moment().format('YYYY-MM-') + '17', title: 'Multi1' },
    { startDate: moment().format('YYYY-MM-') + '24', endDate: moment().add('months', 4).format('YYYY-MM-') + '27', title: 'Multi2' }
    
  ]
  
  link: (scope, element, attrs) ->
    temp = $("##{$(element).attr('id')}-template").html()
    console.log temp
    $(element).clndr
      multiDayEvents:
          startDate: 'startDate'
          endDate: 'endDate'
      template: temp
      events: events
      clickEvents:
        click: (target) ->
          if target.events.length
            daysContainer = $(element).find('.days-container')
            daysContainer.toggleClass('show-events', true)
            $(element).find('.x-button').click ->
              daysContainer.toggleClass 'show-events', false
      adjacentDaysChangeMonth: true

  restrict: 'E'
  replace: true
  transclude: true
  template: "<div ng-transclude></div>"