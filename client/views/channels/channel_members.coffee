Template.channelMembers.events

  'keyup .channel-members-search input': (e) ->
    Session.set('channelMemberSearch', $(e.currentTarget).val())


Template.channelMembers.helpers

  members: ->
    search = $.trim(Session.get('channelMemberSearch'))
    if search && search.length
      search = new RegExp(".*#{search}.*", 'i')
      ChannelMembers.find({channelId: @_id, status: 'active', username: search}, {limit: 20, sort: {createdAt: 1}})
    else
      ChannelMembers.find({channelId: @_id, status: 'active'}, {limit: 20, sort: {createdAt: 1}})


Template.channelMembers.rendered = ->
  Session.set('channelMemberSearch', null)
