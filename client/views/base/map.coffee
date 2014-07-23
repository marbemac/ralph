Template.map.helpers


  map: ->
    if Session.get('gmapsLoaded')

      location = Deps.nonreactive ->
        Session.get('location')

      if location
        coordinates = location.coordinates
      else
        coordinates = null

      gmap.initialize(coordinates, {zoom: 13, disableDefaultUI: true}, $('#map-canvas'), 'global-map')
      return ''

    "<div class='center-muted-notice'>loading map</div>"
