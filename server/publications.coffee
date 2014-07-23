# -------------------------------------------- Posts -------------------------------------------- //

Meteor.publish 'channelPosts', (channelId, channelSlug) ->
  return false unless channelId || channelSlug

  if channelSlug
    channel = Channels.findOne({slug: channelSlug}, {fields: {_id: 1}})
    channelId = channel._id

  Posts.find({channel: channelId},
    {
      sort: {created: -1}
      limit: 20
      fields: {
        '_id','content','username','cc','pp','loc','created','system','private','userId','channel','pid','flagged','entities','admin','moderator'
      }
    }
  )


Meteor.publish 'channelMedia', (channelId, channelSlug) ->
  return false unless channelId || channelSlug

  if channelSlug
    channel = Channels.findOne({slug: channelSlug}, {fields: {_id: 1}})
    channelId = channel._id

  PostMedia.find({channels: channelId},
    {
      sort: {created: -1}
      limit: 20
    }
  )





# -------------------------------------------- Channels ------------------------------------------ //

Meteor.publish 'channel', (channelId, channelSlug) ->
  if channelSlug
    channel = Channels.findOne({slug: channelSlug}, {fields: {_id: 1}})
    channelId = channel._id
  Channels.find channelId


Meteor.publish 'channels', (channelIds) ->
  Channels.find({_id: {$in: channelIds}}, {fields: {userData: 0, users: 0}})


Meteor.publish 'popularGlobalChannels', ->
  Channels.find({type: 'global', status: 'active'}, {sort: {userCount: -1}, limit: 20})


Meteor.publish 'globalChannelSearch', (searchValue) ->
  search = new RegExp(".*#{slugify(searchValue)}.*", 'i')
  Channels.find({slug: search, type: 'global', status: 'active'}, {sort: {userCount: -1}, limit: 10})


Meteor.publish 'newGlobalChannels', ->
  Channels.find({type: "global", status: 'active'}, {sort: {created: -1}, limit: 10, fields: {userData: 0, users: 0}})



# -------------------------------------------- Channel Members -------------------------------------------- //


Meteor.publish 'userChannelMemberInfo', ->
  return unless @userId
  ChannelMembers.find({userId: @userId, status: 'active'})


Meteor.publish 'channelMembers', (channelId) ->
  ChannelMembers.find({channelId: channelId})


# -------------------------------------------- Users -------------------------------------------- //

Meteor.publish "userData", ->
  Meteor.users.find @userId

Meteor.publish "user", (username) ->
  Meteor.users.find {slug: slugify(username)},
                    {fields: {'username'}}
