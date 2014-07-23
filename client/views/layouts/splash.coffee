Template.splash.counter = 0

Template.splash.events

  'click .splash-mark': (e) ->
    Template.splash.counter += 1
    if Template.splash.counter >= 5
      $('.splash-middle').hide()
      $('.login-form').show()
