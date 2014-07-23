# _id
#
# userId
# channelId
# roles []
# createdAt - when they joined
# lastSeen - when they last opened the channel
# username
# cc - chat color
# pi - profile image
# mpid - mobile push id
# notify - bool, should this user be notified on updates to this channel
# status - active,inactive,kicked
# kickedReason
# kickedBy - userId that kicked this user
# kickedAt - when they were kicked



@ChannelMembers = new Meteor.Collection("channelMembers")


Meteor.methods


  createChannelMember: (channelId, userId) ->
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    if existingMember
      if existingMember.status == 'inactive'
        ChannelMembers.update(existingMember._id, {$set: {status: 'active'}})
      return existingMember._id

    channel = Channels.findOne(channelId)
    return unless channel

    user = Meteor.users.findOne(userId)
    return unless user

    memberId = ChannelMembers.insert({
      userId: userId
      channelId: channelId
      roles: []
      createdAt: new Date().getTime()
      username: user.username
      cc: user.chatColor
      pi: user.pi
      mpid: user.mobilePushId
      notify: true
      status: 'active'
      })


  removeChannelMember: (channelId, userId) ->
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    return false unless existingMember

    ChannelMembers.update(existingMember._id, {$set: {status: 'inactive'}})
    true


  toggleChannelMemberNotify: (channelId, userId) ->
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    return unless existingMember

    ChannelMembers.update(existingMember._id, {$set: {notify: !existingMember.notify}})


  addChannelMemberRole: (channelId, userId, role) ->
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    return unless existingMember

    ChannelMembers.update(existingMember._id, {$addToSet: {roles: role}})


  removeChannelMemberRole: (channelId, userId, role) ->
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    return unless existingMember

    ChannelMembers.update(existingMember._id, {$pull: {roles: role}})


  kickChannelMember: (channelId, userId, kickedReason) ->
    user = Meteor.user()
    return unless user

    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId})
    return unless existingMember

    ChannelMembers.update(existingMember._id, {$set: {status: 'kicked', kickedReason: kickedReason, kickedBy: user._id, kickedAt: new Date().getTime()}})
