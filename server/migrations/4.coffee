Migrations.add
  version: 4
  name: 'Make sure push ids are ok.'
  up: ->
    users = Meteor.users.find().fetch()
    for user in users
      pushIds = user.pushChannels
      newPushIds = []
      if pushIds && pushIds.length
        for pushId in pushIds
          if _.contains(_.union(user.globalChannels, user.localChannels, user.openPrivateChannels), pushId)
            newPushIds.push pushId
          else
            console.log "discard push id #{pushId} for user #{user.username}"
        Meteor.users.update(user._id, {$set: {pushChannels: newPushIds}})
