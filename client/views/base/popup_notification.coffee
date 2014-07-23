Template.popupNotification.events


  'click': (e) ->
    clearNotification @id, @thisElement


Template.popupNotification.rendered = ->
  @data.thisElement = $(@firstNode)

  $self = @
  setTimeout ->
    $self.data.thisElement.addClass('popup-notification--visible')
  , 100

  if @data.autoClose
    $self = @
    setTimeout ->
      clearNotification $self.data.id, $self.data.thisElement
    , @data.autoClose
