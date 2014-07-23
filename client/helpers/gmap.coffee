@gmap =

  # map object
  map: null
  maps: {}
  currentMapId: null
  mapCenters: {}

  latLngs: {}
  markers: {}
  markerData: {}

  circles: {}
  circleData: {}

  bounds: {}
  rectangles: {}
  rectangleData: {}

  retryAttempts: 0

  # add a marker given our formatted marker data object
  addMarker: (marker) ->
    return if @markerExists('id', marker.id)

    gLatLng = new google.maps.LatLng(marker.coordinates[1],marker.coordinates[0])
    gMarker = new google.maps.Marker(
      position: gLatLng
      map: @map
      title: marker.title

      # animation: google.maps.Animation.DROP
      # icon: "http://maps.google.com/mapfiles/ms/icons/blue-dot.png"
    )

    @latLngs[@currentMapId][marker.id] = gLatLng
    @markers[@currentMapId][marker.id] = gMarker
    @markerData[@currentMapId].push marker
    gMarker


  addSoloMarker: (marker) ->
    for k,data of @markerData[@currentMapId]
      unless marker.id == data.id
        @removeMarker data.id
    @addMarker marker
    @resize()


  removeMarker: (id) ->
    delete @latLngs[@currentMapId][id]
    @markers[@currentMapId][id].setMap null
    delete @markers[@currentMapId][id]
    @markerData[@currentMapId] = _.reject(@markerData[@currentMapId], (data) -> data.id == id)


  # check if a marker already exists
  markerExists: (key, val) ->
    query = {}
    query[key] = val
    return true if _.where(@markerData[@currentMapId], query).length > 0

    false

  # add a circle given our formatted circle data object
  addCircle: (circle) ->
    return if @circleExists('id', circle.id)

    gLatLng = new google.maps.LatLng(circle.coordinates[1],circle.coordinates[0])
    gCircle = new google.maps.Circle(
      strokeWeight: 0
      fillColor: '#27ae60'
      fillOpacity: 0.25
      map: @map
      center: gLatLng
      radius: circle.radius
    )

    @latLngs[@currentMapId][circle.id] = gLatLng
    @circles[@currentMapId][circle.id] = gCircle
    @circleData[@currentMapId].push circle
    gCircle


  addSoloCircle: (circle) ->
    for k,data of @circleData[@currentMapId]
      unless circle.id == data.id
        @removeCircle data.id
    @addCircle circle


  removeCircle: (id) ->
    delete @latLngs[@currentMapId][id]
    @circles[@currentMapId][id].setMap null
    delete @circles[@currentMapId][id]
    @circleData[@currentMapId] = _.reject(@circleData[@currentMapId], (data) -> data.id == id)


  # check if a circle already exists
  circleExists: (key, val) ->
    query = {}
    query[key] = val
    return true if _.where(@circleData[@currentMapId], query).length > 0

    false


  # check if a marker already exists
  rectangleExists: (key, val) ->
    query = {}
    query[key] = val
    return true if _.where(@rectangleData[@currentMapId], query).length > 0

    false


  addPolygon: (bounds) ->
    return if @rectangleExists('id', bounds.id)

    polygonCoords = []
    for coordinates in bounds.coordinates[0]
      polygonCoords.push new google.maps.LatLng(coordinates[1],coordinates[0])

    polygon = new google.maps.Polygon
      paths: polygonCoords,
      strokeColor: '#00BFFF'
      strokeWeight: 2
      strokeOpacity: 0.7
      fillColor: '#00BFFF'
      fillOpacity: 0.15
      map: @map

    @bounds[@currentMapId][bounds.id] = polygonCoords
    @rectangles[@currentMapId][bounds.id] = polygon
    @rectangleData[@currentMapId].push bounds

    polygon


  addSoloPolygon: (bounds) ->
    for data in @rectangleData[@currentMapId]
      unless bounds.id == data.id
        @removeRectangle data.id
    @addPolygon bounds


  removeRectangle: (id) ->
    delete @bounds[@currentMapId][id]
    @rectangles[@currentMapId][id].setMap null
    delete @rectangles[@currentMapId][id]
    @rectangleData[@currentMapId] = _.reject(@rectangleData[@currentMapId], (data) -> data.id == id)


  clearMap: ->
    for data in @markerData[@currentMapId]
      @removeMarker data.id

    for data in @circleData[@currentMapId]
      @removeCircle data.id

    for data in @rectangleData[@currentMapId]
      @removeRectangle data.id


  # calculate and move the bound box based on our markers
  calcBounds: ->
    bounds = new google.maps.LatLngBounds()
    for k,latLng of @latLngs[@currentMapId]
      bounds.extend latLng

    for k,polygon of @rectangles[@currentMapId]
      path = polygon.getPath()
      for latLng in path.getArray()
        bounds.extend latLng

    @map.fitBounds bounds


  _initialize: (center, options, target, mapId) ->
    @currentMapId = mapId

    if center
      @mapCenters[@currentMapId] = new google.maps.LatLng(center[1], center[0])
    else
      if !@mapCenters[@currentMapId]
        @mapCenters[@currentMapId] = new google.maps.LatLng(0,0)

    mapOptions =
      zoom: 14
      center: @mapCenters[@currentMapId]
      mapTypeId: google.maps.MapTypeId.ROADMAP

    if center && options
      for k,option of options
        mapOptions[k] = option


    unless target
      target = $('#map-canvas')

    map = @maps[mapId]

    if map && $(map.getDiv()).closest("html").length # is it still in the dom?
      map.setOptions(mapOptions) if options

      if target.is(':empty')
        target.replaceWith($(map.getDiv()))
    else
      map = new google.maps.Map(target.get(0), mapOptions)
      @maps[mapId] = map
      @latLngs[mapId] = {}
      @markers[mapId] = {}
      @markerData[mapId] = []

      @circles[mapId] = {}
      @circleData[mapId] = []

      @bounds[mapId] = {}
      @rectangles[mapId] = {}
      @rectangleData[mapId] = []

    @map = map
    @clearMap()

    if center && options && options.zoom
      @map.setZoom(options.zoom)


  # intialize the map
  initialize: (center, options, target, mapId) ->
    if (typeof google != 'undefined' && google.maps && typeof google.maps.LatLng != 'undefined')
      @retryAttempts = 0
      @_initialize(center, options, target, mapId)
    else if @retryAttempts < 10
      $this = @
      setTimeout ->
        $this.retryAttempts += 1
        $this.initialize(center, options, target, mapId)
      , 50


  resize: ->
    google.maps.event.trigger(@map, 'resize')
    @map.setCenter(@mapCenters[@currentMapId])



  setMap: (mapId) ->
    @currentMapId = mapId
    @map = @maps[mapId]
