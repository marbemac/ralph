Template.channelShow.events
  'click .page-header__center': (e,t) ->
    $(t.find('.page-header')).toggleClass('page-header--expanded')


  'click .page-submenu li': (e,t) ->
    return if $(e.currentTarget).hasClass('on')
    $(e.currentTarget).addClass('on').siblings().removeClass('on')
    $(t.find('.view__carousel')).find('.view__carausel__item').removeClass('on')
    $(t.find($(e.currentTarget).data('target'))).addClass('on')

  'click .channel-join': (e) ->
    Meteor.call 'joinChannel', Session.get('currentChannelId'), null, (err, channel) ->
      if err
        throwError err.reason
      else
        infoNotification("You're now a member of this channel! To leave or change the notification settings of this channel, tap and hold it on the main channel list screen.")

  'click .share': (e) ->
    if Session.get('platform') != 'Web'
      channel = Channels.findOne(Session.get('currentChannelId'))

      user = Meteor.user()
      if user
        member = ChannelMembers.findOne({channelId: Session.get('currentChannelId'), userId: user._id, status: 'active'})
      else
        member = false

      if member && member.roles && _.contains(member.roles, 'admin')
        message = "I just created a channel on @RalphApp for #{channel.name}. Join at https://ralphchat.com/c/#{channel.slug} and let's chat!"
      else
        message = "Interested in #{channel.name}? Join me on @RalphApp at https://ralphchat.com/c/#{channel.slug} and let's chat!"

      window.plugins.socialsharing.share(message, 'Check out this channel on Ralph', null, null)
      analytics.track("Share Started", {type: 'global'})


Template.channelShow.helpers


  channel: ->
    Channels.findOne(Session.get('currentChannelId'))


  isMember: ->
    return false unless Session.get('currentChannelId')
    user = Meteor.user()
    return false unless Meteor.user()
    ChannelMembers.findOne({channelId: Session.get('currentChannelId'), userId: user._id, status: 'active'})

  isAdmin: ->
    return false unless Session.get('currentChannelId')
    user = Meteor.user()
    return false unless Meteor.user()
    member = ChannelMembers.findOne({channelId: Session.get('currentChannelId'), userId: user._id, status: 'active'})
    member && member.roles && _.contains(member.roles, 'admin')
