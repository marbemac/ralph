# _id
# content
# topics
# users
# userId
# private
# system
# created
# channel
# flagged [] - array of userId's that flagged this post
# pid - parent post id
# username - the author's username
# cc - user chat color
# pi - user profile image
# admin bool - this user is admin of this channel
# moderator bool - this user is moderator of this channel
# loc
# # type
# # coordinates
# # accuracy
# # geoName
# # geoType
# media []{}
# # _id - post_media id
# # type - image or link
# # oid - original id
# # id - new id, if applicable
# # w - width, if applicable
# # h - height, if applicable


@Posts = new Meteor.Collection("posts")

@Posts.allow
  update: ownsDocument
  remove: ownsDocument

@Posts.deny update: (userId, post, fieldNames) ->
  # may only edit the following fields:
  _.without(fieldNames, "content", "channels").length > 0


Meteor.methods

  post: (_id, content, currentLocation, currentChannelId, parentPostId) ->
    user = Meteor.user()

    # ensure the user is logged in
    throw new Meteor.Error(401, "Please log in.")  unless user


    media = []
    # parse media in the text
    exp = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
    # content = content.replace(exp,"<a href='$1' target='_blank' rel='nofollow'>$1</a>")
    entityMatches = content.match(exp)
    if entityMatches
      for match in entityMatches

        if Meteor.isServer
          postMedia = Meteor.call 'postMediaFindOrCreateByUrl', match, content, currentChannelId
          newEntity =
            _id: postMedia._id
            type: postMedia.type
            oid: match
          if postMedia.media
            newEntity.nid = postMedia.media.url
            newEntity.h = postMedia.media.h
            newEntity.w = postMedia.media.w
        else
          newEntity =
            oid: match
            processing: true

        media.push newEntity


    # handle media, for now, only a single image
    exp = /<img[^>]+src="?([^"\s]+)"?\s*\>/g
    imageMatches = exp.exec(content)
    if imageMatches
      match = imageMatches[1]
      if match.match(/\.png|\.jpg|\.jpeg|\.gif/i)
        newId = "{image-1}"
        # insert the image id placeholder
        regex = new RegExp("<img.*?src=\"#{match}\">", "ig")
        content = content.replace(regex, newId)

        # add the placeholder entity
        if Meteor.isServer
          media.push
            type: 'image'
            oid: newId
        else
          # push this for the client to immediately show the image
          media.push
            type: 'image'
            oid: newId
            id: match
            toUpload: match
            processing: true

    # clean content
    if Meteor.isServer
      SanitizeHtml = Meteor.npmRequire('sanitize-html')
      content = SanitizeHtml(content, {allowedTags: [], allowedAttributes: {}})
      Sanitizer = Meteor.npmRequire('sanitizer')
      content = Sanitizer.sanitize(content)
    else
      tmpContent = document.createElement("DIV")
      tmpContent.innerHTML = content
      content = tmpContent.textContent || tmpContent.innerText || ""
    content = content.trim()

    # ensure the post has content
    throw new Meteor.Error(422, "Type something.")  unless content && content.length > 0

    post =
      _id: _id
      content: content
      topics: []
      users: []
      userId: user._id
      created: new Date().getTime()
      private: false
      username: user.username
      cc: user.chatColor
      pi: user.pi

    # does the post have media
    if media.length
      post.media = media

    # does the post have a @user(s)
    users = post.content.match(/(@[a-zA-Z0-9]+)/gi)
    if users
      for tmpUser in users
        tmpUser = tmpUser.replace('@','')
        post.users.push tmpUser unless tmpUser == null || tmpUser == undefined

    # add location data if present
    if currentLocation
      post.loc = _.extend(type: 'Point', _.pick(currentLocation,'coordinates','accuracy'))

    currentChannel = Channels.findOne(currentChannelId)

    throw new Meteor.Error(404, "Sorry, we couldn't find the chat you are trying to post to.")  unless currentChannel
    throw new Meteor.Error(401, "Sorry, this chat has been disabled.") unless currentChannel.status == 'active'

    member = ChannelMembers.findOne({channelId: currentChannel._id, userId: user._id, status: 'active'})
    throw new Meteor.Error(401, "Sorry, you are not a member of this channel.")  unless member

    post.channel = currentChannel._id
    post.private = currentChannel.private

    if _.contains(member.roles, 'admin')
      post.admin = true

    if _.contains(member.roles, 'moderator')
      post.moderator = true

    if post.loc && _.contains(['local','place'], currentChannel.type)
      post.loc.geoName = currentChannel.name
      post.loc.geoType = currentChannel.type

    postId = Posts.insert(post)

    newPost = Posts.findOne(postId)
    unless newPost
      throw new Meteor.Error(422, "Your message could not be created. There was an unknown error. Please let us know if this continues to happen.")

    if currentChannel
      now = new Date().getTime()
      Channels.update(currentChannel._id, {$inc: {messageCount: 1}, $set: {lastMessageCreated: now, lastAuthor: post.username, lastChatColor: user.chatColor}})


    # PUSH NOTIFICATIONS
    Meteor.call 'sendPostPushNotifications', user, newPost, currentChannel

    newPost


  flagPost: (postId) ->
    user = Meteor.user()

    throw new Meteor.Error(401, "Please log in.")  unless user

    Posts.update(postId, {$addToSet: {flagged: user._id}})



  createSystemPost: (message, currentChannelId) ->
    post =
      content: message
      created: new Date().getTime()
      system: true
      private: false

    post.channel = currentChannelId if currentChannelId

    postId = Posts.insert(post)



  sendPostPushNotifications: (user, newPost, currentChannel) ->
    return if Meteor.isClient # don't actually need to run this on the client

    pushUsers = []

    # if there were @users mentioned, only send to them
    if newPost.users && newPost.users.length > 0
      pushUsers = _.union(pushUsers, newPost.users)
    else
      # the users with notifications on for this channel
      if currentChannel
        notificationOnUsers = ChannelMembers.find({channelId: currentChannel._id, notify: true}).fetch()

        # if this channel has a parent, only push to the user if they have the parent open
        # right now parents are only systemChannels, so just check that
        if currentChannel.parent && currentChannel.parent._id
          for user in notificationOnUsers
            if _.contains(user.localSystemChannels, currentChannel.parent._id)
              pushUsers.push user.username
        else
          pushUsers = _.union(pushUsers, _.pluck(notificationOnUsers, 'username'))


    if pushUsers.length > 0
      userPushIds = []
      pushUsers = _.uniq(pushUsers)
      fullUsers = Meteor.call('findUserByUsernames', pushUsers).fetch()

      for targetUser in fullUsers
        # this user is not the username, has a mobile push id, and is not currently looking at this channel
        if targetUser && targetUser.username != newPost.username && targetUser.mobilePushId #&& !(currentChannel && currentChannel._id == targetUser.activeChannel)
          userPushIds.push targetUser.mobilePushId

      if userPushIds.length > 0
        userPushIds = _.uniq(userPushIds)

        message = newPost.username
        if currentChannel && currentChannel.name
          message += " in \"#{currentChannel.name}\""
        message += ": #{newPost.content}"
        message = message.replace(/&nbsp;/g, ' ').substring(0, 300).trim()

        UA = Meteor.npmRequire('urban-airship')
        ua = new UA(Meteor.settings.UA_APP_KEY, Meteor.settings.UA_APP_SECRET, Meteor.settings.UA_APP_MASTER_SECRET)

        uaPayload =
          "device_tokens": userPushIds
          "aps":
            "alert": message
            "badge": "+1"
          "url": if currentChannel then "/c/#{currentChannel.slug}" else '/'

        ua.pushNotification "/api/push", uaPayload, (err) ->
          # do something with the error?
          if err
            console.log err
          return
