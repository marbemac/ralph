# Used to load external libraries on demand (like google maps)
IRLibLoader = {} if typeof IRLibLoader is "undefined"

IRLibLoader._libs = IRLibLoader._libs or {}

IRLibLoader.load = (src) ->
  self = @
  unless @_libs[src]
    @_libs[src] =
      src: src
      ready: false
      readyDeps: new Deps.Dependency
    $.getScript(src, (data, textStatus, jqxhr) ->
      lib = self._libs[src]
      if jqxhr.status is 200
        lib.ready = true
        lib.readyDeps.changed()
    )

  handle =
    ready: () ->
      lib = self._libs[src]
      lib.readyDeps.depend()
      return lib.ready

  return handle

IRLibLoader.load('https://maps.googleapis.com/maps/api/js?key=AIzaSyBEJwuJOVsVFgVdNN0FmLLPLqGwmswQaaI&sensor=true&callback=gmapsLoaded')


showViewOne = ->
  $('#container').removeClass('show-left-menu show-view-two show-view-three show-view-four').addClass('show-view-one')
showViewTwo = ->
  $('#container').removeClass('show-left-menu show-view-one show-view-three show-view-four').addClass('show-view-two')
showViewThree = ->
  $('#container').removeClass('show-left-menu show-view-one show-view-two show-view-four').addClass('show-view-three')
showViewFour = ->
  $('#container').removeClass('show-left-menu show-view-one show-view-two show-view-three').addClass('show-view-four')
isMobile = ->
  typeof device != 'undefined'


Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
  notFoundTemplate: 'notFound'
  onRun: ->
    analytics.page()
  # disableProgressSpinner: true


Router.map ->

  @route 'channelCreate',
    path: '/c/create'
    onBeforeAction: ->
      showViewFour()
      Session.set('currentChannelId', null)
    action: ->
      @render 'channelCreate', {to: 'view-four'}


  @route 'channelRemove',
    path: '/c/remove'
    onBeforeAction: ->
      showViewFour()
    action: ->
      @render 'channelRemove', {to: 'view-four'}


  @route 'channelShow',
    path: '/c/:slug'
    onRun: ->
      Session.set('currentPage', 'channel')
    onBeforeAction: ->
      showViewTwo()

      # redirect the user to the app on their phone if possible
      if Session.get('platform') == 'Web' && ($.browser.ipad || $.browser.iphone)
        window.location = "ralph://?page=#{window.location.pathname}"
    waitOn: ->
      [Meteor.subscribe('channel', null, @params.slug), Meteor.subscribe('channelPosts', null, @params.slug)]
    onAfterAction: ->
      channel = Channels.findOne({slug: @params.slug})
      if channel
        Session.set('currentChannelId', channel._id)
        Meteor.subscribe 'channelMembers', channel._id
        Meteor.subscribe 'channelMedia', channel._id


  @route 'globalChannels',
    path: '/channels'
    onRun: ->
      Session.set('currentPage', 'globalChannels')
    onBeforeAction: ->
      if $('body').width() >= 900
        showViewFour()
      else
        showViewOne()
    action: ->
      if $('body').width() >= 900
        @render 'home', {to: 'view-four'}
    onAfterAction: ->
      Session.set('currentChannelId', null)


  @route 'channelPermalink',
    path: '/cid/:_id'
    onRun: ->
      Session.set('currentPage', 'channel')
    onBeforeAction: ->
      showViewTwo()
      Session.set('currentChannelId', @params._id)
    waitOn: ->
      [Meteor.subscribe('channel', @params._id), Meteor.subscribe('channelPosts', @params._id)]


  @route 'localChannel',
    path: '/local'
    onRun: ->
      Session.set('currentPage', 'localChannel')
    onBeforeAction: ->
      showViewThree()
      startWatchingLocation()
      Session.set('currentChannelId', null)
    onStop: ->
      $('.local-map').removeClass('local-map--show')
      stopWatchingLocation()


  @route 'about',
    path: '/about'
    onRun: ->
      Session.set('currentPage', 'about')
    onBeforeAction: ->
      showViewFour()
    action: ->
      @render 'about', {to: 'view-four'}


  @route 'channelShowDeprecated',
    path: '/:slug'
    onBeforeAction: ->
      @redirect 'channelShow', {slug: @params.slug}


  @route 'home',
    path: '/'
    onRun: ->
      Session.set('currentPage', 'home')
    onBeforeAction: ->
      if Meteor.user()
        Router.go 'localChannel'
    action: (pause) ->
      unless Meteor.loggingIn() || Meteor.user()
        @render 'login', {to: 'page-cover'}


closeLeftMenu = ->
  $('#container').removeClass('show-left-menu')

# usernameize = ->
#   Router.go('home') unless Meteor.user()

loggingIn = (pause) ->
  unless Meteor.user()
    # render the login template but keep the url in the browser the same
    if Meteor.loggingIn()
      @render('loggingIn')
      pause()

authorizeAdmin = (pause) ->
  unless (Meteor.user() && Meteor.user().admin) || Meteor.loggingIn()
    Router.go 'localChannel'
    pause()


loginFirst = (pause) ->
  unless Meteor.user() || Meteor.loggingIn()
    @render('login', {to: 'page-cover'})
    pause()

sniffBrowser = (pause) ->
  unless isMobile() || $.browser.webkit || $.browser.mozilla || ($.browser.msie && parseInt($.browser.versionNumber) >= 10)
    @render('unsupportedBrowser', {to: 'page-cover'})
    pause()


Router.onBeforeAction(sniffBrowser)
Router.onBeforeAction(loginFirst, only: ['channelCreate', 'localChannel'])
Router.onBeforeAction(closeLeftMenu)
Router.onBeforeAction(loggingIn)
Router.onBeforeAction(authorizeAdmin, only: ['channelRemove','localChannelCreate'])
# Router.onBeforeAction(usernameize, except: ['home'])
