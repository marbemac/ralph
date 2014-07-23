Template.channelRemove.events

  'click .center-form__submit': (e) ->
    console.log 'fo'
    slug = $('.chat__name').val()
    Meteor.call 'removeChannel', slug, (err) ->
      if err
        throwError err.reason
      else
        infoNotification('Chat Removed!')
        $('.chat__name').val('')
