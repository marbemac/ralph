Template.loginForm.events

    'click .login-form__sign-up': (e, t) ->
      e.preventDefault()

      username = $.trim(t.find("[name=login]").value)
      password = $.trim(t.find('[name=password]').value)

      unless username.match(/^[a-z0-9_]+$/i)
        throwError "Your username can only include letters, numbers, and underscores."
        return

      if password.length < 6
        throwError('Your password must be at least 6 characters long')
        return

      $(e.currentTarget).text('Working..').attr('disabled', 'disabled')

      Meteor.call 'findUserByUsername', username, (err, user) ->
        if user
          Meteor.loginWithPassword user.username, password, (err, user) ->
            $(e.currentTarget).text('Log In').removeAttr('disabled')
            if (err)
              throwError(err.reason)
            else
              analytics.track("Login")
        else
          Meteor.call 'findUserByDeviceUUID', Session.get('deviceUUID'), (err, user) ->
            if user
              $(e.currentTarget).text('Sign Up').removeAttr('disabled')
              throwError('Sorry, only one account is allowed per mobile device (for now).')
              return

            Accounts.createUser {username: username, password: password}, (err) ->
              if (err)
                $(e.currentTarget).text('Sign Up').removeAttr('disabled')
                throwError(err.reason)
              else
                analytics.track("Signup")
                Router.go("about")


    'click .login-form__log-in': (e, t) ->
      e.preventDefault()

      username = $.trim(t.find("[name=login]").value)
      password = $.trim(t.find('[name=password]').value)

      $(e.currentTarget).text('Working..').attr('disabled', 'disabled')

      Meteor.call 'findUserByUsername', username, (err, user) ->
        $(e.currentTarget).text('Log In').removeAttr('disabled')
        if user
          Meteor.loginWithPassword user.username, password, (err, user) ->
            if (err)
              throwError(err.reason)
            else
              analytics.track("Login")
        else if err
          throwError(err.reason)
