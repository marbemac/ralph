# Meteor.AppCache.config
  # onlineOnly: ['/images/']

Facts.setUserIdFilter (userId) ->
  user = Meteor.users.findOne(userId)
  return user && user.slug == 'marc'
