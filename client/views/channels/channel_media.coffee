Template.channelMedia.helpers

  media: ->
    PostMedia.find({channels: @_id}, {sort: {created: 1}, limit: 20})
