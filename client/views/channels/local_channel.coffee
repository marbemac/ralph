Template.localChannel.helpers

  channel: ->
    location = Session.get('location')
    if location && location.channelId
      channel = Channels.findOne(location.channelId)
      # Session.set('currentChannel', channel)
      channel
    else
      null


Template.localChannel.events

  'click .show-map': (e) ->
    localMap = $('.local-map')

    if localMap.is(':visible')
      localMap.removeClass('local-map--show')
    else
      location = Session.get('location')
      if location && location.channelId
        channel = Channels.findOne(location.channelId)
      else
        return

      if channel

        localMap.addClass('local-map--show')

        location = Session.get('location')

        if location
          gmap.initialize([location.coordinates[0], location.coordinates[1]], {zoom: 13, disableDefaultUI: true}, $('#map-canvas'), 'global-map')
          locationId = "#{location.coordinates[0]}#{location.coordinates[1]}-#{channel._id}".replace(/-|\./g, '')


          targetChannel = channel
          if channel.parent
            targetChannel = Channels.findOne(channel.parent._id)

          if targetChannel.bounds
            bounds =
              id: targetChannel._id
              coordinates: targetChannel.bounds.coordinates
            gmap.addSoloPolygon(bounds)
            gmap.calcBounds()


          gmap.resize()
