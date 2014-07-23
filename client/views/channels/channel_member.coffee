Template.channelMember.helpers

  isAdmin: ->
    _.contains(@roles, 'admin')
