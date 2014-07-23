ralphFeedbackId = "542fd3a822d71fecf985b99a"

Deps.autorun ->
  search = Session.get('channelSearch')
  if search && search.length
      Meteor.subscribe 'globalChannelSearch', search
  else
    Meteor.subscribe 'popularGlobalChannels'


Deps.autorun ->
  user = Meteor.user()
  if user
    Meteor.subscribe('userData')
    Meteor.subscribe('channels', user.globalChannels) if user.globalChannels
    Meteor.subscribe('userChannelMemberInfo')

    # save the users device uuid
    if typeof device != 'undefined' && (!user.deviceUUIDs || !_.contains(user.deviceUUIDs, device.uuid))
      Meteor.call 'updateUserDeviceUUID', device.uuid

    # update the mobile push id if we have it
    if window.pushId && user.mobilePushID != window.pushId
      Meteor.call 'updatePushId', window.pushId


Deps.autorun ->
  if Meteor.userId()
    channelId = Session.get('currentChannelId')
    Meteor.call 'setUserActiveChannel', channelId


Deps.autorun ->
  if Meteor.userId()
    location = Session.get('location')

    if location && location.channelId
      Meteor.subscribe 'channel', location.channelId
      Meteor.subscribe 'channelPosts', location.channelId
