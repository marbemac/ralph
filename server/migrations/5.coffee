Migrations.add
  version: 5
  name: 'Move to separate channel members collection.'
  up: ->
    channels = Channels.find().fetch()
    for channel in channels
      for k,user of channel.userData
        existingMember = ChannelMembers.findOne({channelId: channel._id, userId: k})
        unless existingMember

          ChannelMembers.insert({
            userId: k
            channelId: channel._id
            roles: []
            createdAt: user.when
            username: user.username
            cc: user.cc
            pi: user.pi
            mpid: user.mobilePushId
            notify: true
            status: 'active'
            })

      Channels.update(channel._id, {$unset: {userData: "", users: ""}})
