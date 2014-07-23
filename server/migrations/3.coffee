Migrations.add
  version: 3
  name: 'More channel cleaning.'
  up: ->
    ids = ["rM6zM8cCCGWXhBBuD", "GWDJ3gnX7f6GRiZsd", "jBwS7dqMyd7h2sSp6", "abx5FQDbnZR85mrFn"]
    channels = Channels.find({_id: {$in: ids}}).fetch()
    for channel in channels
      for userId in channel.users
        userUpdateQuery = {$pull: {localChannels: channel._id, globalChannels: channel._id, openTopicChannels: channel._id, openPrivateChannels: channel._id, pushChannels: channel._id}}
        Meteor.users.update(userId, userUpdateQuery)

      Channels.remove(channel._id)

    users = Meteor.users.find({}).fetch()
    for user in users
      if user.globalChannels
        for channelId in user.globalChannels
          channel = Channels.findOne(channelId)
          if channel && channel.type == 'local'
            updateQuery = {$inc: {userCount: -1}, $pull: {activeUsers: user.username, users: user._id}, $unset: {}}
            updateQuery.$unset["userData.#{user._id}"] = 1
            Channels.update(channelId, updateQuery)

            userUpdateQuery = {$pull: {globalChannels: channelId, pushChannels: channelId}}
            Meteor.users.update(user._id, userUpdateQuery)
