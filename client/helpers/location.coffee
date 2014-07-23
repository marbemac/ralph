# degrees to radians
deg2rad = (degrees) ->
  Math.PI * degrees / 180.0

# radians to degrees
rad2deg = (radians) ->
 180.0 * radians / Math.PI

# Semi-axes of WGS-84 geoidal reference
WGS84_a = 6378137.0  # Major semiaxis [m]
WGS84_b = 6356752.3  # Minor semiaxis [m]

# Earth radius at a given latitude, according to the WGS-84 ellipsoid [m]
WGS84EarthRadius = (lat) ->
  # http://en.wikipedia.org/wiki/Earth_radius
  An = WGS84_a * WGS84_a * Math.cos(lat)
  Bn = WGS84_b * WGS84_b * Math.sin(lat)
  Ad = WGS84_a * Math.cos(lat)
  Bd = WGS84_b * Math.sin(lat)
  Math.sqrt( (An*An + Bn*Bn)/(Ad*Ad + Bd*Bd) )

# Bounding box surrounding the point at given coordinates,
# assuming local approximation of Earth surface as a sphere
# of radius given by WGS84
@boundingBox = (latitudeInDegrees, longitudeInDegrees, radiusInMeters, reverseCoords) ->
  lat = deg2rad(latitudeInDegrees)
  lon = deg2rad(longitudeInDegrees)

  # Radius of Earth at given latitude
  radius = WGS84EarthRadius(lat)
  # Radius of the parallel at given latitude
  pradius = radius*Math.cos(lat)

  latMin = rad2deg(lat - radiusInMeters/radius)
  latMax = rad2deg(lat + radiusInMeters/radius)
  lonMin = rad2deg(lon - radiusInMeters/pradius)
  lonMax = rad2deg(lon + radiusInMeters/pradius)

  if reverseCoords
    [[lonMax, latMin], [lonMax, latMax], [lonMin, latMax], [lonMin, latMin], [lonMax, latMin]]
  else
    [[latMin, lonMax], [latMax, lonMax], [latMax, lonMin], [latMin, lonMin], [latMin, lonMax]]




@gmapsLoaded = ->
  Session.set('gmapsLoaded', new Date().getTime())


isGatheringLocation = false


@stopWatchingLocation = ->
  if window.locationChecking
    clearInterval window.locationChecking
    window.locationChecking = null


@startWatchingLocation = ->
  return if window.locationChecking

  Session.set('locationGathering', true)

  getLocation()

  window.locationChecking = setInterval ->
    getLocation()
  , 60000


locationSuccess = (p) ->
  isGatheringLocation = false

  accuracy = Math.round(p.coords.accuracy)

  if accuracy > 1000
    getLocation()
    return

  location = Deps.nonreactive ->
    Session.get('location')

  location ||= {}

  Session.set('locationError', null)
  Session.set('locationGathering', false)

  now = new Date().getTime() / 1000

  # update if it's the first time
  # update if we haven't updated in the last 30 seconds
  # update if the accuracy has improved
  if !location.lastUpdated || now - location.lastUpdated > 30 || accuracy < location.accuracy
    location.lastUpdated = now
    location.coordinates = [p.coords.longitude, p.coords.latitude]
    location.accuracy = accuracy
    location.bounds = boundingBox(p.coords.latitude, p.coords.longitude, accuracy, true)

    Meteor.call 'findOrCreateLocalSystemChannel', location.coordinates[1], location.coordinates[0], location.bounds, (err, channelId) ->
      console.log channelId
      if err || !channelId
        location.channelId = null
      else
        location.channelId = channelId
      Session.set('location', location)
      Session.set('locationGatheringMessage', false)

    if accuracy > 20
      Session.set('locationAccuracy', accuracy)
    else
      Session.set('locationAccuracy', "< 20")

  if accuracy > 300
    setTimeout ->
      getLocation()
    , 5000




locationError = (err) ->
  isGatheringLocation = false
  Session.set('locationGathering', null)
  Session.set('locationAccuracyMessage', null)

  if err.code == 1
    Session.set('locationError', "Looks like you denied Ralph access to your location! You won't be able to see, create, or join local chats :(. If you change your mind, please give Ralph location permissions by going to Settings -> Privacy -> Location Services in your phone and turning on Ralph.")
    Session.set('location', null)
  if err.code == 3
    location = Deps.nonreactive ->
      Session.get('location')
    if !location || location && (new Date().getTime() / 1000 - location.lastUpdated) > 300
      Session.set('locationError', "Your GPS timed out while Ralph was trying to get your location! Let us know if this continues to happen @RalphApp on Twitter or support@ralphchat.com.")
      Session.set('location', null)
      analytics.track("Location Denied", {code: err.code, userId: Meteor.user()._id})

locationOptions =
  enableHighAccuracy: true
  timeout: 60000
  maximumAge: 0

@getLocation = () ->
  return if isGatheringLocation

  if window.appRunning
    isGatheringLocation = true
    navigator.geolocation.getCurrentPosition(locationSuccess, locationError, locationOptions)
