Meteor.startup ->

  Migrations.migrateTo('latest')

  # indexes
  Posts._ensureIndex({ loc: "2dsphere" })
  Posts._ensureIndex({ channel: 1, created: -1 })

  PostMedia._ensureIndex({ url: 1 })
  PostMedia._ensureIndex({ channels: 1, created: -1 })

  Channels._ensureIndex({ bounds: "2dsphere" })
  Channels._ensureIndex({ center: "2dsphere" })
  Channels._ensureIndex({ "parent._id": 1 })
  Channels._ensureIndex({ slug: 1 })
  Channels._ensureIndex({ userId: 1, userCount: 1 })

  ChannelMembers._ensureIndex({ channelId: 1, userId: 1, status: 1 })
  ChannelMembers._ensureIndex({ userId: 1, status: 1 })

  Meteor.users._ensureIndex({ pushChannels: 1 })
  Meteor.users._ensureIndex({ slug: 1 })
  Meteor.users._ensureIndex({ deviceUUIDs: 1 })

  # connect to meteor kadira
  if Meteor.settings.METEOR_KADIRA_APP_ID && Meteor.settings.METEOR_KADIRA_APP_SECRET
    Kadira.connect(Meteor.settings.METEOR_KADIRA_APP_ID, Meteor.settings.METEOR_KADIRA_APP_SECRET)

  # settings to send down to the client
  __meteor_runtime_config__.IMAGE_ROOT_URL = process.env.IMAGE_ROOT_URL

  # Seed all the geo data DEPRECATED
  # fileNames = [
  #   'ak','al','ar','az','ca','co','ct','dc','fl','ga','hi','ia','id','il','in','ks','ky',
  #   'la','ma','md','me','mi','mn','mo','ms','mt','nc','ne','nj','nm','nv','ny','oh','or','pa','ri','tn',
  #   'tx','ut','va','wa','wi'
  # ]

  # Fiber = Npm.require('fibers')
  # Fiber(->
  #   count = 0
  #   fs = Meteor.require('fs')
  #   for name in fileNames
  #     fs.readFile "#{process.env.PWD}/server/geo_data/#{name}.json", 'utf8', (err,data) ->
  #       if err
  #         console.log err
  #         return

  #       entries = JSON.parse(data)

  #       for k,feature of entries['features']
  #         channelData =
  #           name: feature.properties.NAME
  #           description: ''

  #         location =
  #           state: feature.properties.STATE
  #           county: feature.properties.COUNTY
  #           city: feature.properties.CITY
  #           type: 'neighborhood'

  #         console.log "CREATING #{feature.properties.NAME}"
  #         Fiber(->
  #           try
  #             Meteor.call 'createChannel', channelData, 'local', true, 'admin', location, feature.geometry.coordinates[0], null, null, null
  #           catch error
  #             console.log error
  #             console.log "ERROR for #{feature.properties.NAME}"
  #         ).run()

  #     count += 1
  #   console.log "*** DONE: inserted #{count} local channels ***"
  # ).run()
