Template.messageList.helpers

  isGlobal: ->
    @type == 'global'

  posts: ->
    Posts.find({channel: @_id}, {sort: {created: 1}, limit: 20})

  # nestedPosts: ->
  #   posts = Posts.find({channel: @_id}, {sort: {created: 1}}).fetch()
  #   previousUserId = null
  #   nestedPosts = []
  #   for post in posts
  #     if post.userId == previousUserId
  #       nestedPosts[nestedPosts.length - 1].posts.push post
  #     else
  #       nestedPosts.push {username: post.username, cc: post.cc, posts: [post]}
  #       previousUserId = post.userId
  #   nestedPosts

# Template.messageList.rendered = ->
  # Session.set('messageListAutoScroll', true)
  # messageList = $(@find('.messages-list'))

  # $self = @
  # setTimeout ->
  #   $($self.firstNode).scroll($.throttle( 50, (e) ->
  #       target = $(e.currentTarget)

  #       # we're near the bottom
  #       if target.scrollTop() + target.outerHeight() > messageList.outerHeight() - 100
  #         Session.set('messageListAutoScroll', true)
  #       else
  #         Session.set('messageListAutoScroll', false)
  #     )
  #   )
  # , 250

