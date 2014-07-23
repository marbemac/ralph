Migrations.add
  version: 2
  name: 'Remove old channels.'
  up: ->
    ids = ["GWDJ3gnX7f6GRiZsd","rM6zM8cCCGWXhBBuD","DCBaltimorePhilly"]
    channels = Channels.find({_id: {$in: ids}}).fetch()
    for channel in channels
      for userId in channel.users
        userUpdateQuery = {$pull: {localChannels: channel._id, globalChannels: channel._id, openTopicChannels: channel._id, openPrivateChannels: channel._id, pushChannels: channel._id}}
        Meteor.users.update(userId, userUpdateQuery)

      Channels.remove(channel._id)
