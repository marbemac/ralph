Template.layout.helpers

  userMenuIsOnClass: (name) ->
    'on' if Session.get('currentPage') == name

  offline: ->
    if Meteor.status().connecting || !Meteor.status().connected
      setTimeout ->
        $('.try-reconnect').show()
      , 5000
      true

  pageStyle: ->
    channelId = Session.get('currentChannelId')
    if channelId
      channel = Channels.findOne(channelId)
    else
      channel = Session.get('pendingChannel') # used for channel creation preview

    if channel
      style = ""
      if channel.bgImage
        if channel._id
          style += "background-image: url('#{Meteor.settings.public.IMAGE_ROOT_URL+channel.bgImage}');"
        # else
        #   style += "background-image: url('#{channel.bgImage}');"
      style += "background-size: #{channel.bgImageW}px #{channel.bgImageH}px;" if channel.bgImageH && channel.bgImageW
      if channel.bgImage
        if channel.bgImageR
          style += "background-repeat: repeat; background-position: center center;"
        else if channel.bgImageF
          style += "background-repeat: no-repeat; background-position: 50% center; background-size: cover;"
      else
        style += 'background-position: left top; background-size: auto; background-repeat: no-repeat;'
        if channel.bgColor
          style += 'background-image: none;'
      style += "background-color: #{channel.bgColor};" if channel.bgColor
      style
    else
      ""


Template.layout.events

  # open external links in external browser
  'click .message__content a': (e) ->
    if Session.get('platform') != 'Web' && Session.get('appVersion') <= 1.0
      e.preventDefault()
    else if Session.get('platform') != 'Web'
      target = e.currentTarget.getAttribute("href")
      unless target[0] != '/' || target.match('ralphchat.com')
        e.preventDefault()
        window.open(target, '_blank', 'location=yes');

  'click #hide-left-menu': (e) ->
    $('#container').removeClass('show-left-menu')

  'click #container__inner': (e) ->
    unless $(e.target).hasClass('left-menu-toggle') || $(e.target).parent().hasClass('left-menu-toggle')
      $('#container').removeClass('show-left-menu')

  'click .left-menu-toggle': (e) ->
    $('#container').toggleClass('show-left-menu')

  'click .logout': (e) ->
    Meteor.logout (err) ->
      # Router.go 'home' unless err

  'click .server-facts': (e) ->
    $(e.currentTarget).toggleClass('server-facts--show')

  'click .try-reconnect': (e) ->
    Meteor.reconnect()

  'click .top-menu .pane-names__item': (e) ->
    clicked = $(e.currentTarget)
    paneBg = clicked.siblings('.pane-names__bg:first')
    paneNames = clicked.parent().find('.pane-names__item')
    paneNameWidth = clicked.outerWidth()
    paneCount = paneNames.length
    paneContainer = clicked.parents('.panes:first').children('ul')
    panes = paneContainer.children('li')
    paneWidth = panes.width()
    showIndex = paneNames.index(e.currentTarget)

    paneOffset = -1 * showIndex / paneCount * 100

    paneContainer.css("transform", "translate3d(#{paneOffset}%,0,0)");
    paneBg.css('left', showIndex * paneNameWidth)

  'click .sidebar-invite-friends': (e) ->
    if Session.get('platform') != 'Web'

      window.plugins.socialsharing.share("I just got @RalphApp, it makes it easy to chat with people nearby. Check it out! https://appsto.re/i66q8p3", 'Check out Ralph', null, null)
      analytics.track("Sidebar Share Started")



Template.layout.rendered = ->
  FastClick.attach(document.body)
