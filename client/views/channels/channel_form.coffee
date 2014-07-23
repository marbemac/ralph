createTopicChannel = ->
  submitButton = $('.channel-form__submit div')
  return if submitButton.hasClass('disabled')
  submitPreviousVal = submitButton.text()
  submitButton.text('Working...').addClass('disabled')

  pendingChannel.name = $.trim(pendingChannel.name)
  pendingChannel.description = $.trim(pendingChannel.description)

  if pendingChannel.name.length < 3
    throwError "Your channel's name must be longer than 2 characters long."
    submitButton.text(submitPreviousVal).removeClass('disabled')
    return

  if pendingChannel.name.length > 20
    throwError "Your channel's name must be less than 20 characters long."
    submitButton.text(submitPreviousVal).removeClass('disabled')
    return

  if pendingChannel.description.length > 500
    throwError "Your channel's description must be less than 500 characters. It currently has #{description.length}."
    submitButton.text(submitPreviousVal).removeClass('disabled')
    return

  unless pendingChannel.name.match(/^[a-z0-9 ]+$/i)
    throwError "Your channel name can only include numbers, letters, and spaces."
    submitButton.text(submitPreviousVal).removeClass('disabled')
    return

  # update if existing channel, else create new
  if pendingChannel._id
    Meteor.call "updateChannel", pendingChannel._id, pendingChannel, (error) ->
      submitButton.text(submitPreviousVal).removeClass('disabled')
      if error
        throwError error.reason
      else
        options =
          name: name
        analytics.track("Channel Updated", options)
        infoNotification("Your updates have been saved.")
        $('input').blur()
  else
    Meteor.call "createChannel", pendingChannel, 'global', false, 'user', null, null, null, null, null, (error, channel) ->
      if error
        submitButton.text(submitPreviousVal).removeClass('disabled')
        throwError error.reason
        if error.details
          Router.go('channel', {slug: error.details})
      else
        Session.set('pendingChannel', null)
        options =
          name: name
          withImage: (if channel.image then true else false)
          withBGImage: (if channel.bgImage then true else false)
          withBGRepeat: channel.bgImageR
          withBGFill: channel.bgImageF
          withBGDefault: (if !channel.bgImageR && !channel.bgImageR then true else false)
          withBGColor: (if channel.bgColor then true else false)
        analytics.track("Channel Created", options)
        infoNotification("Channel created!")
        $('input').blur()
        Router.go 'channelShow', {slug: channel.slug}


Template.channelForm.helpers

  pendingChannel: ->
    Session.get('pendingChannel')

  bgThemeClass: (type) ->
    tmpPendingChannel = Session.get('pendingChannel')
    return unless tmpPendingChannel
    if type == 'repeat'
      'on' if tmpPendingChannel.bgImageR
    else if type == 'fill'
      'on' if tmpPendingChannel.bgImageF
    else
      'on' if !tmpPendingChannel.bgImageF && !tmpPendingChannel.bgImageR

Template.channelForm.events


  "submit form": (e) ->
    e.preventDefault()

  "keyup .channel-form__name": (e) ->
    pendingChannel.name = $(e.currentTarget).val()
    Session.set('pendingChannel', pendingChannel)

  "keyup .channel-form__description": (e) ->
    pendingChannel.description = $(e.currentTarget).val()
    Session.set('pendingChannel', pendingChannel)

  "focus textarea": (e) ->
    setTimeout ->
      $('.pane__inner:visible').scrollTo('max', 300)
    , 0
    setTimeout ->
      $(e.currentTarget).select()
    , 400

  "click .channel-form__submit": (e) ->
    createTopicChannel()

  "click .refresh": (e) ->
    pendingChannel.image = null
    pendingChannel.bgColor = null
    pendingChannel.bgImage = null
    pendingChannel.bgImageR = false
    pendingChannel.bgImageF = false
    Session.set('pendingChannel', pendingChannel)

  "click .channel-form__bg-theme div": (e) ->
    type = $(e.currentTarget).data('type')
    pendingChannel.bgImageF = false
    pendingChannel.bgImageR = false
    if type == 'fill'
      pendingChannel.bgImageF = true
    else if type == 'repeat'
      pendingChannel.bgImageR = true
    Session.set("pendingChannel", pendingChannel)

  "click .channel-form__theme-option--image": (e) ->
    target = $('.channel-form__image-selector')
    if target.hasClass('visible')
      target.removeClass('visible')
    else
      $('.bottom-panel').removeClass('visible')
      target.addClass('visible')

  "click .channel-form__image-selector .submit": (e) ->
    urlInput = $('.channel-form__image-selector input')
    url = urlInput.val()
    urlInput.val('')
    pendingChannel.image = url
    Session.set('pendingChannel', pendingChannel)
    $('.bottom-panel').removeClass('visible')

  "click .channel-form__theme-option--bgimage": (e) ->
    target = $('.channel-form__bgimage-selector')
    if target.hasClass('visible')
      target.removeClass('visible')
    else
      $('.bottom-panel').removeClass('visible')
      target.addClass('visible')

  "click .channel-form__bgimage-selector .submit": (e) ->
    urlInput = $('.channel-form__bgimage-selector input')
    url = urlInput.val()
    urlInput.val('')
    pendingChannel.bgImage = url
    Session.set('pendingChannel', pendingChannel)
    $('.bottom-panel').removeClass('visible')



pendingChannel = null
pendingChannelAutorun = null
Template.channelForm.rendered = ->
  existingPending = Session.get('pendingChannel')
  pendingChannel =
    name: ''
    description: ''
    image: null
    bgColor: null
    bgImage: null
    bgImageR: false
    bgImageF: false

  pendingChannelAutorun = Deps.autorun ->
    if Session.get('currentChannelId') # it's already been saved, we're editing
      channel = Channels.findOne(Session.get('currentChannelId'))
      Session.set('pendingChannel', channel)
      pendingChannel = channel
    else
      if existingPending && !existingPending._id
        pendingChannel = Session.get('pendingChannel')
      else
        Session.set('pendingChannel', pendingChannel)

  $(".channel-form__theme-option--bgcolor").spectrum({
      color: "#FFF"
      change: (color) ->
        pendingChannel.bgColor = color.toHexString()
        Session.set('pendingChannel', pendingChannel)
  });


  # Hammer($('.channel-form').get(0)).on "swipedown", (e) ->
  #   e.gesture.preventDefault()
  #   $('input').blur()


Template.channelForm.destroyed = ->
  Session.set('pendingChannel', null)
  pendingChannelAutorun.stop() if pendingChannelAutorun
  target = $(".channel-form__theme-option--bgcolor")
  if target.length
    target.spectrum('destroy')
