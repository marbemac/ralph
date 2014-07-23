# _id
# username
# slug
# pi - profile image
# activeChannel
# activeChannelWhen
# chatColor
# createdAt
# deviceUUIDs []
# mobilePushId
# lastLocation
# # type
# # coordinates
# # accuracy
# lastLocationWhen
# notificationCount
# pushChannels [] - the channelIds this user receives push notifications for
# localSystemChannels [] - currently joined local system channel ids
# localChannels [] - the currently joined local channel ids
# globalChannels [] - the current joined global channel ids
# openPrivateChannels [] ** TODO: change this to privateChannels to match convention
# services {}

Meteor.methods

  findUserByUsername: (username) ->
    console.log username
    Meteor.users.findOne {slug: slugify(username)}, {reactive: false}


  findUserByUsernames: (usernames) ->
    slugified = _.map(usernames, (username) -> slugify(username))
    Meteor.users.find {slug: {$in: slugified}}, {reactive: false}


  findUserByIds: (ids) ->
    Meteor.users.find {_id: {$in: ids}}, {reactive: false}


  # update a user's mobilePushId
  updatePushId: (pushId) ->
    Meteor.users.update(@userId, {$set: {mobilePushId: pushId}})


  resetUserNotificationCount: ->
    user = Meteor.user()
    throw new Meteor.Error(401, "Please log in.")  unless user
    Meteor.users.update(user._id, {$set: {notificationCount: 0}})


  updateUserDeviceUUID: (uuid) ->
    throw new Meteor.Error(401, "Please log in.")  unless @userId
    return unless uuid
    Meteor.users.update(@userId, {$addToSet: {deviceUUIDs: uuid}})


  findUserByDeviceUUID: (uuid) ->
    Meteor.users.findOne(deviceUUIDs: uuid) if uuid


  clearUserLocationChannels: ->
    throw new Meteor.Error(401, "Please log in.")  unless @userId
    user = Meteor.user()
    if user.openLocationChannels && user.openLocationChannels.length > 0
      Meteor.users.update(@userId, {$set: {openLocationChannels: []}})

if Meteor.isServer
  Meteor.methods

    setUserActiveChannel: (channelId) ->
      Deps.nonreactive ->
        user = Meteor.user()

        throw new Meteor.Error(401, "Please log in.")  unless user

        return if user.activeChannel == channelId

        now = new Date().getTime()

        console.log "set activeChannel #{channelId}"

        # only proceed if the user is looking at a different channel
        if user.activeChannel != channelId
          # remove from active users in old channel
          if user.activeChannel
            channel = Channels.findOne(user.activeChannel)
            if channel
              Channels.update(user.activeChannel, {$pull: {activeUsers: user.username}})

          Channels.update(channelId, {$addToSet: {activeUsers: user.username}})
          Meteor.users.update(user._id, {$set: {activeChannel: channelId, activeChannelWhen: now}})
