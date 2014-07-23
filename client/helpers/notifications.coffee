@clearNotifications = ->
  $('.popup-notification').removeClass('popup-notification--visible')
  setTimeout ->
    Session.set('notifications', [])
  , 500


@clearNotification = (id, targetElement) ->
  targetElement.removeClass('popup-notification--visible')

  setTimeout ->
    notifications = Deps.nonreactive ->
      Session.get('notifications')

    return unless notifications

    notifications = _.reject(notifications, (item) -> item.id == id)
    Session.set('notifications', notifications)
  , 500


addNotification = (content, type) ->
  notifications = Deps.nonreactive ->
    Session.get('notifications')

  notifications ||= []
  notifications.push {
      id: new Date().getTime()
      message: content
      type: type
      autoClose: 7500
    }

  Session.set('notifications', notifications)


@infoNotification = (content) ->
  addNotification(content, 'info')


@throwError = (content) ->
  addNotification(content, 'error')
