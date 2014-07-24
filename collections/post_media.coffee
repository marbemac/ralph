# _id
# type
# url
# title
# provider
# channels
# media
# createdAt

@PostMedia = new Meteor.Collection("post_media")

if Meteor.isServer
  Meteor.methods

    postMediaFindOrCreateByUrl: (url, content, channelId) ->
      user = Meteor.user()
      throw new Meteor.Error(401, "Please log in.")  unless user

      if url
        existing = PostMedia.findOne({url: url})
        if existing
          unless _.contains(existing.channels, channelId)
            PostMedia.update(existing._id, {$addToSet: {channels: channelId}})
          return existing

      embedlyData = Meteor.call 'fetchEmbedlyUrl', url
      if embedlyData

        # one more check
        existing = PostMedia.findOne({url: embedlyData.url})
        if existing
          unless _.contains(existing.channels, channelId)
            PostMedia.update(existing._id, {$addToSet: {channels: channelId}})
          return existing

        postMedia =
          type: embedlyData.type
          url: embedlyData.url
          title: if embedlyData.title then embedlyData.title else content
          provider: embedlyData.provider_display
          channels: [channelId]
          userId: user._id

        if embedlyData.images
          result = Async.runSync (done) ->
            cloudinary = Meteor.require('cloudinary')
            cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
            cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
            cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
            cloudinary.uploader.upload embedlyData.images[0].url, (result) ->
              done(null, result)
            , crop: "limit", width: 1000, height: 1000

          if result && result.result
            result = result.result
            postMedia.media =
              url: "/v#{result.version}/#{result.public_id}.#{result.format}"
              w: result.width
              h: result.height


        postMedia.createdAt = new Date().getTime()
        postMediaId = PostMedia.insert(postMedia)
        postMedia._id = postMediaId
        postMedia


    postMediaCreateImage: (imageUrl, content, channelId) ->
      # user = Meteor.user()
      # throw new Meteor.Error(401, "Please log in.")  unless user

      result = Async.runSync (done) ->
        cloudinary = Meteor.require('cloudinary')
        cloudinary.config('cloud_name', Meteor.settings.CLOUDINARY_CLOUD_NAME)
        cloudinary.config('api_key', Meteor.settings.CLOUDINARY_API_KEY)
        cloudinary.config('api_secret', Meteor.settings.CLOUDINARY_API_SECRET)
        cloudinary.uploader.upload imageUrl, (result) ->
          done(null, result)
        , crop: "limit", width: 1000, height: 1000

      if result && result.result
        result = result.result

        postMedia =
          type: 'image'
          title: content
          channels: [channelId]
          # userId: user._id
          media:
            url: "/v#{result.version}/#{result.public_id}.#{result.format}"
            h: result.height
            w: result.width

        postMediaId = PostMedia.insert(postMedia)
        postMedia._id = postMediaId
        postMedia
