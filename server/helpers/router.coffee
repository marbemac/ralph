Router.map ->

  @route 'uploadPostImage',
    path: '/posts/image/upload'
    where: 'server'
    action: ->
      params = @request.body
      post = Posts.findOne(params.postId)
      if post
        file = @request.files.file
        if file
          postMedia = Meteor.call 'postMediaCreateImage', file.path, post.content, post.channel
          console.log {_id: params.postId, "media.oid": params.entityOID}, {$set: {"media.$._id": postMedia._id, "media.$.id": postMedia.media.url, "media.$.h": postMedia.media.h, "media.$.w": postMedia.media.w}}
          Posts.update({_id: params.postId, "media.oid": params.entityOID}, {$set: {"media.$._id": postMedia._id, "media.$.id": postMedia.media.url, "media.$.h": postMedia.media.h, "media.$.w": postMedia.media.w}})
