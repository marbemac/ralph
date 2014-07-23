Template.globalChannels.events

  'click .page-submenu li': (e,t) ->
    return if $(e.currentTarget).hasClass('on')
    $(e.currentTarget).addClass('on').siblings().removeClass('on')
    $(t.find('.view__carousel')).find('.view__carausel__item').removeClass('on')
    $(t.find($(e.currentTarget).data('target'))).addClass('on')


  'click .create-channel': (e) ->
    Session.set('pendingChannel', null)


  'keyup .channel-search': (e,t) ->
    Session.set('channelSearch', $.trim($(e.currentTarget).val()))


Template.globalChannels.helpers

  openChannels: ->
    user = Meteor.user()
    return [] unless user && user.globalChannels
    Channels.find({_id: {$in: user.globalChannels}}, {sort: {userCount: -1}}).fetch()

  popularChannels: ->
    search = $.trim(Session.get('channelSearch'))

    if search && search.length
      search = new RegExp(".*#{slugify(search)}.*", 'i')
      Channels.find({type: "global", slug: search}, {sort: {userCount: -1}, limit: 10})
    else
      Channels.find({type: "global", status: 'active'}, {sort: {userCount: -1}, limit: 20})


  # newChats: ->
  #   Channels.find({global: true}, {sort: {created: -1}, limit: 10})
