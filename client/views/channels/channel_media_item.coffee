Template.channelMediaItem.helpers


  mediaUrl: ->
    if @media && @media.url
      @media.url
    else
      null
