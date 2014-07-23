handleIncomingPush = (incoming) ->
  if incoming && incoming.extras && incoming.extras.url
    Router.go(incoming.extras.url)

Meteor.startup ->
  # if somehow we reloaded the page without reloading phonegap, we need to reload phonegap..
  if Session.get('phonegapLocation') && typeof device == 'undefined' # yes old phonegap location, but no phonegap data
    window.location.href = "#{Session.get('phonegapLocation')}?page=#{window.location.pathname}"

  if (typeof phonegapLocation != 'undefined')
    console.log 'setting phonegapLocation'
    Session.set('phonegapLocation', phonegapLocation)

  if typeof device != 'undefined'
    Session.set('platform', device.model)
    Session.set('appVersion', __MeteorRiderConfig__.appVersion)
    Session.set('os', device.version)
  else
    Session.set('platform', 'Web')
    Session.set('appVersion', 1.1)

  # when the mobile app is paused (backgrounded for example)
  document.addEventListener "pause", ->
    status = Meteor.status()
    if status.connected || status.status == 'connecting'
      console.log 'METEOR: App paused.'
      Meteor.disconnect()
      window.appRunning = false
      stopWatchingLocation()
  , false

  # when the mobile app resumes
  document.addEventListener "resume", ->
    status = Meteor.status()
    if !status.connected && !status.connecting
      console.log 'METEOR: App resumed.'
      $('.try-reconnect').hide()
      Meteor.reconnect()
      window.appRunning = true
      startWatchingLocation()

      if window.pushId
        PushNotification.getIncoming handleIncomingPush
  , false

  # when the mobile device goes offline
  document.addEventListener "offline", ->
    Session.set('mobileOffline', true)
  , false

  # when the mobile device comes line
  document.addEventListener "online", ->
    Session.set('mobileOffline', false)
  , false

  window.appRunning = true

  if (window.location.host == "ralphchat.com")
    Session.set('environment', 'Production')
  else if (window.location.host == "staging.ralphchat.com")
    Session.set('environment', 'Staging')
  else
    Session.set('environment', 'Development')

  console.log "running in #{Session.get('environment')}"

  # handle incoming push notifications on first load
  if window.pushId
    PushNotification.getIncoming handleIncomingPush
