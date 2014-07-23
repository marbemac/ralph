Meteor.methods

  fetchEmbedlyUrl: (url) ->

    data = Async.runSync (done) ->
      embedly = Meteor.require('embedly')
      new embedly {key: '1acfc6d105ea48f0b0c4bddf08c06195'}, (err, api) ->
        if err
          done(err, null)

        api.extract {url: url}, (err, objs) ->
          if err
            done(err, null)

          done(null, objs[0])

    if data.error
      console.log data.error
    else
      data.result
