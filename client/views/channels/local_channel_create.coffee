`
/**
 * requestAnimationFrame and cancel polyfill
 */
(function() {
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame =
                window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
                    timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };

    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());

/**
* super simple carousel
* animation between panes happens with css transitions
*/
function Carousel(element, enableDragging)
{
    var self = this;
    element = $(element);

    var container = $(">ul", element);
    var panes = $(">ul>li", element);

    var pane_names = $(".pane-names__item", element);
    var pane_names_bg = $(".pane-names__bg", element);
    var pane_names_width = pane_names_bg.width();

    var pane_width = 0;
    var pane_count = panes.length;

    var current_pane = 0;


    /**
     * initial
     */
    this.init = function() {
        setPaneDimensions();

        $(window).on("load resize orientationchange", function() {
            setTimeout(function() {
                setPaneDimensions();
            }, 1000);
            //updateOffset();
        })
    };


    /**
     * set the pane dimensions and scale the container
     */
    function setPaneDimensions() {
        pane_width = element.width();
        panes.each(function() {
            $(this).width(pane_width);
        });
        container.width(pane_width*pane_count);
    };


    /**
     * show pane by index
     */
    this.showPane = function(index, animate) {
        // between the bounds
        index = Math.max(0, Math.min(index, pane_count-1));
        current_pane = index;

        var offset = -((100/pane_count)*current_pane);
        setContainerOffset(offset, animate);
    };


    function setContainerOffset(percent, animate) {
        container.removeClass("animate");

        if(animate) {
            container.addClass("animate");
        }

        if(Modernizr.csstransforms3d) {
            container.css("transform", "translate3d("+ percent +"%,0,0) scale3d(1,1,1)");
        }
        else if(Modernizr.csstransforms) {
            container.css("transform", "translate("+ percent +"%,0)");
        }
        else {
            var px = ((pane_width*pane_count) / 100) * percent;
            container.css("left", px+"px");
        }

        var pane_names_px = ((pane_names_width*pane_count) / 100) * percent;
        if (pane_names_px != 0) {
            pane_names_px += percent / 100 * (pane_count*4);
        }
        pane_names_bg.css("left", -1 * pane_names_px+"px");
    }

    this.next = function() { return this.showPane(current_pane+1, true); };
    this.prev = function() { return this.showPane(current_pane-1, true); };

    function handleHammer(ev) {
        // disable browser scrolling
        ev.gesture.preventDefault();

        switch(ev.type) {
            case 'dragright':
            case 'dragleft':
                // stick to the finger
                var pane_offset = -(100/pane_count)*current_pane;
                var drag_offset = ((100/pane_width)*ev.gesture.deltaX) / pane_count;

                // slow down at the first and last pane
                if((current_pane == 0 && ev.gesture.direction == "right") ||
                    (current_pane == pane_count-1 && ev.gesture.direction == "left")) {
                    drag_offset *= .4;
                }

                setContainerOffset(drag_offset + pane_offset);
                break;

            case 'swipeleft':
                self.next();
                ev.gesture.stopDetect();
                break;

            case 'swiperight':
                self.prev();
                ev.gesture.stopDetect();
                break;

            case 'release':
                // more then 50% moved, navigate
                if(Math.abs(ev.gesture.deltaX) > pane_width/2) {
                    if(ev.gesture.direction == 'right') {
                        self.prev();
                    } else {
                        self.next();
                    }
                }
                else {
                    self.showPane(current_pane, true);
                }
                break;
        }
    }

    if (enableDragging) {
      var hammertime = new Hammer(element[0], { drag_lock_to_axis: true });
      element.on("release dragleft dragright swipeleft swiperight", handleHammer);
    }

    pane_names.on("click", function(e) {
      self.showPane(pane_names.index(e.currentTarget), true);
    })
}
`

Template.localChannelCreate.markers = []
Template.localChannelCreate.poly = null
Template.localChannelCreate.map = null

setMap = ->

  mapOptions =
    zoom: 14
    center: new google.maps.LatLng(0,0)
    mapTypeId: google.maps.MapTypeId.ROADMAP

  map = new google.maps.Map($('.channel-create__map-placeholder').get(0), mapOptions)

  isClosed = false

  Template.localChannelCreate.poly = new google.maps.Polyline(
    map: map
    path: []
    strokeColor: "#FF0000"
    strokeOpacity: 1.0
    strokeWeight: 2
  )

  google.maps.event.addListener map, "click", (clickEvent) ->
    return  if isClosed
    markerIndex = Template.localChannelCreate.poly.getPath().length
    isFirstMarker = markerIndex is 0
    marker = new google.maps.Marker(
      map: map
      position: clickEvent.latLng
      draggable: true
    )

    Template.localChannelCreate.markers.push marker

    if isFirstMarker
      google.maps.event.addListener marker, "click", ->
        return  if isClosed
        path = Template.localChannelCreate.poly.getPath()
        Template.localChannelCreate.poly.setMap null
        Template.localChannelCreate.poly = new google.maps.Polygon(
          map: map
          path: path
          strokeColor: "#FF0000"
          strokeOpacity: 0.8
          strokeWeight: 2
          fillColor: "#FF0000"
          fillOpacity: 0.35
        )

        bounds = []
        for latLng in path.getArray()
          lat = latLng.lat()
          lng = latLng.lng()
          bounds.push [lng,lat]
        bounds.push bounds[0]
        Session.set('currentBounds', bounds)
        isClosed = true

    google.maps.event.addListener marker, "drag", (dragEvent) ->
      Template.localChannelCreate.poly.getPath().setAt markerIndex, dragEvent.latLng
      path = Template.localChannelCreate.poly.getPath()
      bounds = []
      for latLng in path.getArray()
        lat = latLng.lat()
        lng = latLng.lng()
        bounds.push [lng,lat]
      bounds.push bounds[0]
      Session.set('currentBounds', bounds)

    Template.localChannelCreate.poly.getPath().push clickEvent.latLng

  Template.localChannelCreate.map = map

  return ''


Template.localChannelCreate.events


  # http://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&sensor=true_or_false

  'submit .channel-map-form': (e) ->
    e.preventDefault()
    address = $(e.currentTarget).find('.bottom-form__input')
    $.ajax
      url: "https://maps.googleapis.com/maps/api/geocode/json?address=#{address.val()}&sensor=true"
      type: 'GET'
      success: (data) ->
        address.val('')
        if data.results && data.results[0]
          center = new google.maps.LatLng(data.results[0].geometry.location.lat, data.results[0].geometry.location.lng)
          Template.localChannelCreate.map.setCenter(center)


  'submit .channel-form': (e) ->
    $self = @
    e.preventDefault()
    bounds = Session.get('currentBounds')
    name = $(e.currentTarget).find('.channel-form__name')
    locked = $(e.currentTarget).find('.channel-form__locked')

    Meteor.call 'createChannel', {name: name.val()}, 'local', locked.is(':checked'), 'system', null, bounds, null, null, null, (error, channel) ->
      if error
        throwError error.reason
        return

      name.val('')
      Session.set('currentBounds', null)
      $('.channel-create__reset').click()


  'click .channel-create__reset': (e) ->
    for marker in Template.localChannelCreate.markers
      marker.setMap null
      marker = null
    Template.localChannelCreate.poly.setMap null
    Template.localChannelCreate.poly = null
    Session.set('currentBounds', null)
    setMap()


Template.localChannelCreate.rendered = ->
  setTimeout ->
    carousel = new Carousel(".panes--channel-create", false)
    carousel.init()
  , 250

  $self = @
  setTimeout ->
    setMap()
  , 1000
