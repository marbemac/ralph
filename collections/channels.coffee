# _id
# name
# hashtag
# status - default to active. can also be deleted
# type - global, local, private (place, topic deprecated)
# origin - admin, user, system
# private - bool **DEPRECATED
# image - main image
# bgImage - the background image
# bgImageH - image height
# bgImageW - image width
# bgImageR - image repeat
# bgImageF - image fill screen or not (cover basically)
# bgColor - background color
# userId - id of the creator
# creator - username of the creator
# created
# messageCount
# lastAuthor
# lastChatColor
# lastMessageCreated
# priority - used for displaying certain channels higher up (mainly for local system channels), defaults to 0
# parent
# # _id
# # name
# userCount
# activeUsers [] - usernames that currently have this channel open in the app
# location
# # state
# # county
# # city
# # postalCode
# # type
# # size
# center
# # type
# # coordinates
# bounds
# # type
# # coordinates

@Channels = new Meteor.Collection("channels")


Meteor.methods

  # TODO: roll this method into the general createChannel method below
  # createPrivateChannel: (channelId) ->
  #   user = Meteor.user()

  #   # ensure the user is logged in
  #   throw new Meteor.Error(401, "Please log in.")  unless user

  #   # don't allow more than one existing empty channel
  #   existing = Channels.findOne({users: user._id, userCount: 1, private: true})
  #   throw new Meteor.Error(422, "You may only create one empty private chat at a time. Invite people to this chat first!", existing._id)  if existing

  #   channel =
  #     _id: channelId
  #     type: 'private'
  #     origin: 'user'
  #     private: true
  #     userId: user._id
  #     creator: user.username
  #     created: new Date().getTime()
  #     messageCount: 0
  #     lastMessageCreated: 99999999999999 # in the future, so it appears at the top of the sidebar
  #     userCount: 0
  #     users: [] # user's allowed in this private channel, separate from activeUsers
  #     userData: {}

  #   channelId = Channels.insert(channel)
  #   Meteor.call 'joinChannel', channelId, false, user._id
  #   channelId


  createChannel: (channelData, type, locked, origin, location, bounds, center, parent, channelId) ->
    user = Meteor.user()

    # ensure the user is logged in
    throw new Meteor.Error(422, "Please include a channel name longer than 3 characters.")  unless channelData.name && channelData.name.length > 2
    throw new Meteor.Error(422, "Ralph does not support that channel type.")  unless type && _.contains(['global','local','private'], type)
    throw new Meteor.Error(422, "Ralph does not support that origin.")  unless origin && _.contains(['admin','user','system'], origin)
    throw new Meteor.Error(422, "Please include your location when creating a local chat.")  if type == 'local' && origin == 'user' && !parent

    slug = slugify(channelData.name)

    unless type == 'private'
      existingQuery = {"slug": slug, "type": type}
      # todo, check if this name is being used in this local radius if we're using one
      existingChannel = Channels.findOne(existingQuery)
      throw new Meteor.Error(422, "This channel has already been created.", existingChannel._id)  if existingChannel

    channel =
      name: channelData.name
      hashtag: hashify(channelData.name)
      status: 'active'
      slug: slug
      description: channelData.description
      type: type
      created: new Date().getTime()
      messageCount: 0
      locked: locked
      origin: origin
      userCount: 0
      users: []
      userData: {}
      priority: 0
      bgColor: channelData.bgColor
      bgImageR: channelData.bgImageR
      bgImageF: channelData.bgImageF


    # handle images
    if Meteor.isServer
      if channelData.image
        result = Async.runSync (done) ->
          cloudinary = Meteor.npmRequire('cloudinary')
          cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
          cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
          cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
          cloudinary.uploader.upload channelData.image, (result) ->
            done(null, result)
          , crop: "limit", width: 1000, height: 1000
        if result && result.result
          result = result.result
          channel.image = "/v#{result.version}/#{result.public_id}.#{result.format}"
      if channelData.bgImage
        result = Async.runSync (done) ->
          cloudinary = Meteor.npmRequire('cloudinary')
          cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
          cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
          cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
          cloudinary.uploader.upload channelData.bgImage, (result) ->
            done(null, result)
          , crop: "limit", width: 1000, height: 1000
        if result && result.result
          result = result.result
          channel.bgImage = "/v#{result.version}/#{result.public_id}.#{result.format}"
    else
      channel.image = channelData.image
      channel.bgImage = channelData.bgImage

    if user
      channel.userId = user._id
      channel.creator = user.username

    if bounds && bounds.length > 0
      channel.bounds =
        type: 'Polygon'
        coordinates: [bounds]

    if center
      channel.center =
        type: 'Point'
        coordinates: center.coordinates
      if center.accuracy
        channel.center.accuracy = center.accuracy

    if channelId
      channel._id = channelId

    channel.location = location if location

    if parent
      channel.parent = {}
      channel.parent._id = parent._id
      channel.parent.name = parent.name

    channelId = Channels.insert(channel)
    channel._id = channelId

    # join the channel
    if user
      Meteor.call 'joinChannel', channel._id, user._id
      Meteor.call 'addChannelMemberRole', channel._id, user._id, 'admin'

    channel


  updateChannel: (channelId, channelData) ->
    user = Meteor.user()

    throw new Meteor.Error(404, "Please log in first.") unless user

    throw new Meteor.Error(422, "Please include a channel name longer than 3 characters.")  unless channelData.name && channelData.name.length > 2

    existingChannel = Channels.findOne(channelId)
    throw new Meteor.Error(404, "Sorry, that channel could not be found.")  unless existingChannel

    channelUpdates =
      description: channelData.description
      bgColor: channelData.bgColor
      bgImageR: channelData.bgImageR
      bgImageF: channelData.bgImageF

    # handle images
    if Meteor.isServer
      if channelData.image != existingChannel.image
        result = Async.runSync (done) ->
          cloudinary = Meteor.npmRequire('cloudinary')
          cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
          cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
          cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
          cloudinary.uploader.upload channelData.image, (result) ->
            done(null, result)
          , crop: "limit", width: 1000, height: 1000
        if result && result.result
          result = result.result
          channelUpdates.image = "/v#{result.version}/#{result.public_id}.#{result.format}"
      if channelData.bgImage != existingChannel.bgImage
        result = Async.runSync (done) ->
          cloudinary = Meteor.npmRequire('cloudinary')
          cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
          cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
          cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
          cloudinary.uploader.upload channelData.bgImage, (result) ->
            done(null, result)
          , crop: "limit", width: 1000, height: 1000
        if result && result.result
          result = result.result
          channelUpdates.bgImage = "/v#{result.version}/#{result.public_id}.#{result.format}"

    Channels.update(channelId, {$set: channelUpdates})


  leaveChannel: (channelId, userId) ->
    if userId
      unless Meteor.user() && Meteor.user().admin
        throw new Meteor.Error(401, "You are not authorized to do that. Tsk Tsk.")
      user = Meteor.users.findOne(userId)
    else
      user = Meteor.user()

    throw new Meteor.Error(401, "Please log in.")  unless user

    # update the member
    removed = Meteor.call 'removeChannelMember', channelId, user._id
    return unless removed


    # update the channel
    updateQuery = {$inc: {userCount: -1}, $pull: {activeUsers: user.username}}
    Channels.update(channelId, updateQuery)


    # update the user
    userUpdateQuery = {$pull: {localSystemChannels: channelId, localChannels: channelId, globalChannels: channelId, openPrivateChannels: channelId}}
    Meteor.users.update(user._id, userUpdateQuery)


    # remove the channel if it's private and there's nobody left in it
    channel = Channels.findOne(channelId)
    if channel && channel.private && channel.userCount == 0
      Channels.remove(channelId)
      null
    else
      channel


  joinChannel: (channelId, userId) ->
    user = Meteor.user()
    if !userId && !user
      return throw new Meteor.Error(401, "Please login first.")

    targetUser = if userId && user._id != userId then Meteor.users.findOne(userId) else user
    throw new Meteor.Error(401, "User not found.")  unless user

    channel = Channels.findOne(channelId)
    throw new Meteor.Error(404, "Could not find channel.")  unless channel

    throw new Meteor.Error(401, "Sorry, this channel has been disabled.") unless channel.status == 'active'

    # already in the chat, just add to active users, and if it's a system add it to the users local system channels
    existingMember = ChannelMembers.findOne({channelId: channelId, userId: userId, status: 'active'})
    if existingMember
      if channel.type == 'local' && channel.origin == 'system'
        Meteor.users.update(targetUser._id, {$addToSet: {localSystemChannels: channelId}})
      Channels.update(channelId, {$addToSet: {activeUsers: targetUser.username}})
      return channel


    # add the member
    member = Meteor.call 'createChannelMember', channelId, targetUser._id
    return unless member


    # update the channel
    updateQuery = {$addToSet: {activeUsers: targetUser.username}, $set: {}}
    # if it's a new user, increment the userCount, and add them to pushUsers by default
    if !existingMember
      updateQuery.$inc = {userCount: 1}
    Channels.update(channelId, updateQuery)


    # update the user
    userUpdateQuery = {}
    if channel.type == 'private'
      userUpdateQuery["$addToSet"] = {openPrivateChannels: channelId}
    else if channel.type == 'global'
      userUpdateQuery["$addToSet"] = {globalChannels: channelId}
    else if channel.type == 'local' && channel.origin != 'system'
      userUpdateQuery["$addToSet"] = {localChannels: channelId}
    else if channel.type == 'local'
      userUpdateQuery["$addToSet"] = {localSystemChannels: channelId}
    Meteor.users.update(targetUser._id, userUpdateQuery)


    # attempt a channel unlock
    if channel.locked
      Meteor.call 'unlockChannel', targetUser, channelId

    channel


  toggleChannelPush: (channelId) ->
    user = Meteor.user()
    throw new Meteor.Error(401, "User not found.")  unless user
    if _.contains(user.pushChannels, channelId)
      Meteor.users.update(user._id, {$pull: {pushChannels: channelId}})
    else
      Meteor.users.update(user._id, {$push: {pushChannels: channelId}})


if Meteor.isServer
  Meteor.methods

    # channelInviteUser: (channelId, username) ->
    #   user = Meteor.user()
    #   targetUser = Meteor.users.findOne(slug: slugify(username))
    #   throw new Meteor.Error(404, "That username cannot be found.")  unless targetUser

    #   Meteor.call 'joinChannel', channelId, false, targetUser._id, (err, channel) ->
    #     unless err
    #       Meteor.call 'createSystemPost', "#{user.username} invited #{targetUser.username}", channelId
    #       Meteor.call 'sendChannelInvitePushNotifications', user, targetUser, channel


    findLocalSystemChannelByLocation: (lat, lng, bounds) ->
      Channels.findOne(
        {
          bounds:
            $geoIntersects:
              $geometry:
                type: "Polygon"
                coordinates: [bounds]
          type: 'local'
          origin: 'system'
        }
        {
          sort:{
            "priority": -1
          }
          fields: {
            '_id', 'name', 'location', 'priority', 'bounds', 'locked', 'activeUsers', 'origin'
          }
        }
      )


    findOrCreateLocalSystemChannel: (lat, lng, bounds) ->
      return null unless lat && lng

      user = Meteor.user()
      return  unless user

      # try and find a relevant channel
      channel = Meteor.call 'findLocalSystemChannelByLocation', lat, lng, bounds

      # if it didn't find on? let's create one around postal code
      unless channel
        # TODO: use https here
        url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&sensor=true"
        fetch = Meteor.http.get url
        data = fetch.data

        if data && data.results && data.results.length > 0

          for targetTypeName in ['sublocality','locality','administrative_area_level_3','administrative_area_level_2','administrative_area_level_1']
            targetType = _.filter(data.results, (resultData) -> _.contains(resultData.types, targetTypeName))
            if targetType.length
              if targetTypeName == 'sublocality' # check to see if it's a sub of it's parent locality (4th arondissiment of paris for example)
                locality = _.filter(data.results, (resultData) -> _.contains(resultData.types, 'locality'))
                if locality && locality.length
                  locality = locality[0]
                  localityName = _.filter(locality.address_components, (resultData) -> _.contains(resultData.types, 'locality'))[0]["long_name"]
                  sublocalityName = _.filter(targetType[0].address_components, (resultData) -> _.contains(resultData.types, 'sublocality'))[0]["long_name"]

                  if sublocalityName.match(new RegExp(localityName,"gi"))
                    type = 'locality'
                    result = locality
                    break

              type = targetTypeName
              result = targetType[0]
              break

          if result
            boundsTopRightY = result.geometry.bounds.northeast.lat
            boundsTopRightX = result.geometry.bounds.northeast.lng
            boundsBottomLeftY = result.geometry.bounds.southwest.lat
            boundsBottomLeftX = result.geometry.bounds.southwest.lng
            name = _.filter(result.address_components, (resultData) -> _.contains(resultData.types, type))[0]["long_name"]

            bounds = [ [boundsBottomLeftX, boundsTopRightY],[boundsTopRightX, boundsTopRightY],[boundsTopRightX, boundsBottomLeftY],[boundsBottomLeftX, boundsBottomLeftY],[boundsBottomLeftX, boundsTopRightY] ]
            location =
              size: (1000*Math.abs(boundsTopRightY - boundsBottomLeftY)) * (1000*Math.abs(boundsTopRightX - boundsBottomLeftX)) # get the difference in lat/lng to approximate area size
              type: type

            center = null
            if result.geometry.location
              center =
                coordinates: [result.geometry.location.lng, result.geometry.location.lat]

            channel = Meteor.call('createChannel', {name: name}, 'local', true, 'system', location, bounds, center, null, null)


      # still didn't find a suitable place, let's create one manually maybe at some point?
      unless channel
        throw new Meteor.Error(422, "No geocode data for coords [#{lat},#{lng}]")


      # the local channel to leave/join
      channelIds = [channel._id]
      toLeave = _.difference(user.localSystemChannels, channelIds)
      toJoin = _.difference(channelIds, user.localSystemChannels)

      for channelId in toLeave
        Meteor.call 'leaveChannel', channelId
      for channelId in toJoin
        Meteor.call 'joinChannel', channelId

      # unless the user currently has these exact channels open
      unless toLeave.length == 0 && toJoin.length == 0
        console.log "set local system channels to [#{channelIds.join(', ')}]"

      channel._id


    unlockChannel: (user, channelId) ->
      channel = Channels.findOne(channelId)

      # if it's a local channel, use activeUsers since we don't store all the other user info for local channels
      usernames = if channel.type == 'local' then channel.activeUsers else _.pluck(channel.userData, 'username')

      # check to see if we should unlock the channel
      if channel && channel.locked && usernames.length >= 2
        Humanize = Meteor.npmRequire('humanize-plus')
        message = "#{channel.name} "
        if channel.parentName
          message += "in #{channel.parentName} "
        message += "unlocked by #{Humanize.oxford(usernames)}."
        Meteor.call 'createSystemPost', message, channel._id
        Channels.update(channel._id, {$set: {locked: false}})
        Meteor.users.update({username: {$in: usernames}}, {$addToSet: {channelsUnlocked: channel._id}})

        # send an unlock push notification
        Meteor.call 'sendUnlockPushNotification', user, channel


    removeChannel: (slug) ->
      return unless Meteor.user() && Meteor.user().admin
      channel = Channels.findOne({slug: slug})
      unless channel
        throw new Meteor.Error(422, "Channel not found.")
      members = ChannelMembers.find({channelId: channel._id}).fetch()
      for member in members
        Meteor.call 'leaveChannel', channel._id, member.userId
      Channels.update(channel._id, {$set: {status: 'deleted'}})


if Meteor.isServer

  Meteor.methods

    sendChannelInvitePushNotifications: (user, targetUser, channel) ->
      return unless targetUser.mobilePushId

      UA = Meteor.npmRequire('urban-airship')
      ua = new UA(Meteor.settings.UA_APP_KEY, Meteor.settings.UA_APP_SECRET, Meteor.settings.UA_APP_MASTER_SECRET)
      uaPayload =
        "device_tokens": [targetUser.mobilePushId]
        "aps":
          "alert": "#{user.username} invited you to chat!"
          "badge": "+1"
        "url": "/c/#{channel.slug}"

      ua.pushNotification "/api/push", uaPayload, (err) ->
        # do something with the error?
        if err
          console.log err
        return


    sendUnlockPushNotification: (user, channel) ->
      Humanize = Meteor.npmRequire('humanize-plus')
      UA = Meteor.npmRequire('urban-airship')
      ua = new UA(Meteor.settings.UA_APP_KEY, Meteor.settings.UA_APP_SECRET, Meteor.settings.UA_APP_MASTER_SECRET)

      usernames = if channel.type == 'local' then channel.activeUsers else _.pluck(channel.userData, 'username')
      users = Meteor.call('findUserByUsernames', _.without(usernames, user.username)).fetch()

      mobilePushIds = _.without(_.pluck(users, 'mobilePushId'), null, undefined)
      targetUrl = if channel.type == 'local' then '/' else "/c/#{channel.slug}"
      for targetUser in users
        if targetUser.mobilePushId
          humanizedUsers = _.union(['You'], _.without(usernames, targetUser.username))
          uaPayload =
            "device_tokens": [targetUser.mobilePushId]
            "aps":
              "alert": "#{Humanize.oxford(humanizedUsers)} unlocked #{channel.name}!"
              "badge": "+1"
            "url": targetUrl

          ua.pushNotification "/api/push", uaPayload, (err) ->
            # do something with the error?
            if err
              console.log err
            return
