submitMessage = (target, currentTemplate) ->

  originalMessage = $.trim(target.html())

  return unless originalMessage.length > 0
  target.html('')

  _id = new Meteor.Collection.ObjectID()._str

  channelId = currentTemplate.data._id

  Meteor.call "post", _id, originalMessage, Session.get('location'), channelId, null, (error, message) ->
    if Modernizr.touch
      resizeList()

    if error
      # display the error to the user
      throwError error.reason
      target.html(originalMessage)
      # if the error is that the message already exists, take us there
      # Meteor.Router.to "messagePage", error.details  if error.error is 302
    else
      options = {}
      if message.loc
        options.Accuracy = message.loc.accuracy
        options.geoName = message.loc.geoName
        options.geoType = message.loc.geoType
        options.channelId = message.channel
        options.private = message.private
      analytics.track("Message Create", options)



resizeList = (list) ->
  $('.messages-list:visible').parent().scrollTo('max', 300)


onSuccess = (imageURI) ->
  image = $('<img/>')
  image.attr('src', imageURI)
  target = $('.bottom-form__input')
  target.find('img').remove()
  target.prepend(image)

  # move cursor to end of content editable
  target = target.get(0)
  range = document.createRange()
  sel = window.getSelection()
  range.setStart(target, 1)
  range.collapse(true)
  sel.removeAllRanges()
  sel.addRange(range)
  target.focus()
onFail = (message) ->
  # most failures are because the user canceled, so fail silently for now


Template.messageForm.helpers


  getImageClass: ->
    if Session.get('platform') != 'Web' && Session.get('appVersion') > 1.0
      'message-form--with-image'


  canGetImage: ->
    true if Session.get('platform') != 'Web' && Session.get('appVersion') > 1.0


Template.messageForm.events
  'click .message-form__get-image': (e) ->
    navigator.camera.getPicture(
      onSuccess,
      onFail,
      { quality: 50, targetWidth: 1000, targetHeight: 1000, encodingType: Camera.EncodingType.JPEG, destinationType: Camera.DestinationType.FILE_URI }
    )

  "keydown .bottom-form__input": (e,t) ->
    return unless e
    code = (if e.keyCode then e.keyCode else e.which)
    if code == 13 # enter key
      e.preventDefault()
      submitMessage($(e.currentTarget), t)


  'focus .bottom-form__input': (e) ->
    if Modernizr.touch
      setTimeout ->
        resizeList()
      , 0


  'click .bottom-form__input': (e,t) ->
    unless $(e.currentTarget).is(':focus')
      e.preventDefault()
      $(e.currentTarget).focus().select()

    fromBottom = $(window).height() - e.pageY
    fromRight = $(window).width() - e.pageX
    if fromBottom <= 50 && fromRight <= 70
      submitMessage($('.bottom-form__input:visible'), t)


  'touchstart .bottom-form__input': (e) ->
    unless $(e.currentTarget).is(':focus')
      e.preventDefault()
      $(e.currentTarget).focus().select()


Template.messageForm.rendered = ->
  target = @find('.bottom-form__input')
  Hammer($('.messages-list:visible').get(0)).on "swipedown", (e) ->
    e.gesture.preventDefault()
    $(target).blur()


Template.messageForm.destroyed = ->
  Hammer($('.messages-list:visible').get(0)).off "swipedown"

