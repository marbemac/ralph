Migrations.add
  version: 6
  name: 'Add mobile push ids to members.'
  up: ->
    members = ChannelMembers.find().fetch()
    for member in members
      user = Meteor.users.findOne(member.userId)
      if user
        ChannelMembers.update(member._id, {$set: {mpid: user.mobilePushId}})
