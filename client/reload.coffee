Meteor._reload.onMigrate "phonegap", ->
  console.log '** CODE RELOAD **'

  # we need to reload gmaps on every load
  Session.set('gmapsLoaded', null)

  Deps.nonreactive ->
    if Session.get('phonegapLocation')
      console.log 'found phonegapLocation'
      Meteor.defer ->
        window.location.href = "#{Session.get('phonegapLocation')}?page=#{window.location.pathname}"
      return [false]
    else
      console.log 'no phonegapLocation'
      return [true]
