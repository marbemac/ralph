uploadImage = (postId, entity) ->
  ft = new FileTransfer()
  options = new FileUploadOptions()

  options.chunkedMode = false
  options.params = # Whatever you populate options.params with, will be available in req.body at the server-side.
    "entityOID": entity.oid
    "postId": postId

  ft.upload(entity.toUpload, "#{__MeteorRiderConfig__.meteorUrl}/posts/image/upload",
    (e) ->
      console.log e
    ,
    (e) ->
      console.log e
    , options)


Template.message.events

  'click .message': (e,t) ->
    return if Meteor.userId() == @userId || $(e.target).hasClass('message__img-expand') || $(e.target).is('a')

    target = t.$('.message-container')
    if target.hasClass('message-container--show-actions')
      target.removeClass('message-container--show-actions')
      $(e.currentTarget).parents('.messages-list').removeClass('messages-list--show-actions')
    else
      $('.message-container').removeClass('message-container--show-actions')
      target.addClass('message-container--show-actions')
      $(e.currentTarget).parents('.messages-list').addClass('messages-list--show-actions')

  'click .message__flag': (e) ->
    $self = @
    if Session.get('platform') == 'Web'
      Meteor.call 'flagPost', $self._id, (err) ->
        if err
          throwError err.message
    else
      navigator.notification.confirm(
        'Are you sure you want to flag this message?'
        (button) ->
          if button == 2
            Meteor.call 'flagPost', $self._id, (err) ->
              if err
                throwError err.message
        'Flag Message'
        'No,Yes'
      )

  'click .message__img-expand': (e,t) ->
    $target = t.$('.message:first')
    if $target.hasClass('message__img--large')
      return
    $img = $target.find('.message__img').clone()
    $img.on 'click', (e) ->
      setTimeout ->
        $(e.currentTarget).remove()
      , 100
    $img.addClass('message__img--large')
    $('body').append($img)


Template.message.helpers

  hasImage: ->
    true if @entities && _.where(@entities, {type: "image"}).length

  isMine: ->
    true if Meteor.userId() == @userId

  flaggedByMe: ->
    true if @flagged && @flagged.length && _.contains(@flagged, Meteor.userId())

  meClass: ->
    'message--me' if Meteor.userId() == @userId

  systemClass: ->
    'message--system' if @system

  contentWithEntities: ->
    @content = "<p>#{@content}</p>"
    return @content if @loadedForUser

    if @entities && @entities.length
      for entity in @entities
        if entity.type == 'link'
          @content = @content.replace(entity.oid, "<a href='#{entity.oid}' rel='nofollow' target='_blank'>#{entity.oid}</a>")
        else if entity.type == 'image'
          if entity.forClient #
            # mark we've parsed this for the current user and it should not be re-parsed, so we don't have to reload the image
            @loadedForUser = true
            if entity.id
              url = entity.id
            else
              url = entity.oid
            if entity.toUpload
              uploadImage(@_id, entity)
          else # it's been uploaded, we're good to go
            url = Meteor.settings.public.IMAGE_ROOT_URL + "/w_500,h_500,c_limit,f_auto#{entity.id}"
          @content = $.trim(@content.replace(entity.oid, ""))
          @content += "<div class='message__img' style='background-image: url(\"#{url}\")'></div>"

    @content


Template.message.rendered = ->
  # Deps.nonreactive ->
  list = $(@firstNode).parents('.messages-list:visible').parent()
  list.get(0).scrollTop = list.get(0).scrollHeight

#   whenTarget = $(@find('.message__when'))
#   whenTarget.attr('title', moment(@data.created).format())
#   whenTarget.timeago()

  # $(@firstNode).addClass('message--visible')

# Template.message.destroyed = ->
#   return unless @firstNode
#   list = $(@firstNode).parents('.messages-list-wrapper:first')
#   return unless list
#   list.get(0).scrollTop = list.get(0).scrollHeight
