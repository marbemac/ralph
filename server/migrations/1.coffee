Migrations.add
  version: 1
  name: 'Update for localRadius chats.'
  up: ->
    Channels.update({global: true}, {$set: {type: "global"}}, {multi: true})
    Channels.update({private: true}, {$set: {type: "private"}}, {multi: true})
    Channels.update({local: true}, {$set: {type: "local"}}, {multi: true})
    Channels.update({type: "local", center: {$exists: true}, origin: {$ne: "system"}}, {$set: {localRadius: "1m"}}, {multi: true})
    # Channels.find({type: "local", center: {$exists: true}, origin: {$ne: "system"}})

    channels = Channels.find({parentId: {$exists: true}}).fetch()
    for channel in channels
      Channels.update(channel._id, {$unset: {bounds: ""}, $set: {type: "local", localRadius: "1m", parent: {_id: channel.parentId, name: channel.parentName}}})
      Meteor.users.update({_id: {$in: channel.users}}, {$addToSet: {localChannels: channel._id}}, {multi: true})
