Template.channelLocked.helpers

  lockedUserOne: ->
    if @activeUsers && @activeUsers[0]
      @activeUsers[0]
    else
      '???'

  lockedUserTwo: ->
    if @activeUsers && @activeUsers[1]
      @activeUsers[1]
    else
      '???'

  lockedUserThree: ->
    if @activeUsers && @activeUsers[2]
      @activeUsers[2]
    else
      '???'

  lockedUserClass: (which) ->
    'on' if @activeUsers && @activeUsers[which]

  unlocksNeeded: ->
    if @activeUsers
      2 - @activeUsers.length
    else
      2


Template.channelLocked.events

  'click .channel-locked__invite': (e) ->
    if Session.get('platform') != 'Web'
      window.plugins.socialsharing.share("I just got @RalphApp, and I need help unlocking #{@name}. Check it out! https://appsto.re/i66q8p3", 'Check out Ralph', null, null)
      analytics.track("Share Started", {type: 'local'})
