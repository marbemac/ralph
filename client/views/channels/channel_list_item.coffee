isHold = false

closeActions = (e) ->
  $(e.currentTarget).parents('.pretty-item:first').removeClass('pretty-item--show-actions')


Template.channelListItem.helpers


  backgroundStyle: ->
    style = ""
    if @bgImage
      if @_id
        style += "background-image: url('#{Meteor.settings.public.IMAGE_ROOT_URL+@bgImage}');"
      else # this is a new channel, used for preview
        style += "background-image: url('#{@bgImage}');"
    style += "background-size: #{@bgImageW}px #{@bgImageH}px;" if @bgImageH && @bgImageW
    if @bgImageR
      style += "background-repeat: repeat; background-position: center center;"
    else if @bgImage
      style += 'background-repeat: no-repeat; background-position: 50% center; background-size: cover;'

    unless style.length
      style = "background-color: rgba(255,255,255,0.5);"
    style


  roundedImageData: ->
    {username: @lastAuthor, chatColor: @lastChatColor}

  receivesPushNotifications: ->
    userId = Meteor.userId()
    return false unless userId
    member = ChannelMembers.findOne({channelId: @_id, userId: userId, status: 'active'})
    if member then member.notify else false

  name: ->
    if @type == 'local' && @origin == 'system'
      '#General'
    else
      @name
    # user = Meteor.user()
    # if @private
    #   if @users.length > 1
    #     Humanize.oxford(_.without(_.pluck(@userData, 'username'), user.username), 2)
    #   else
    #     "Just You"
    # else

  isLocalSystemChannel: ->
    true if @type == 'local' && @origin == 'system'


Template.channelListItem.events

  'click .pretty-item': (e) ->
    if isHold || $(e.currentTarget).hasClass('pretty-item--show-actions')
      isHold = false
      e.preventDefault()
      return false

  'click .pretty-item__actions .cancel': (e) ->
    if isHold
      isHold = false
    else
      closeActions(e)

  'click .pretty-item__actions .delete': (e) ->
    if isHold
      isHold = false
    else
      closeActions(e)
      Meteor.call 'leaveChannel', @_id, (err) ->
        if err
          throwError err.reason
          return

  'click .pretty-item__actions .toggle-push': (e) ->
    if isHold
      isHold = false
    else
      closeActions(e)
      Meteor.call 'toggleChannelMemberNotify', @_id, Meteor.userId(), (err) ->
        if err
          throwError err.reason
          return


Template.channelListItem.rendered = ->
  target = @find('.pretty-item')
  $self = @

  Hammer(target).on "hold", (e) ->
    isHold = true
    e.preventDefault()
    e.gesture.stopDetect()

    # only allow them to leave if they've joined
    Deps.nonreactive ->
      userId = Meteor.userId()
      return unless userId
      member = ChannelMembers.findOne({channelId: $self.data._id, userId: userId, status: 'active'})
      if member
        $(target).addClass('pretty-item--show-actions')


# Template.channelListItem.destroyed = ->
#   target = @find('.pretty-item')
  # if target
  #   Hammer(@find('.pretty-item')).off('hold')
