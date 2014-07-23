Handlebars.registerHelper 'session', (key) ->
  Session.get(key)

Handlebars.registerHelper 'isMobile', (key) ->
  Session.get('platform') != 'Web'

Handlebars.registerHelper 'urlSlug', (string) ->
  urlSlug(string)

Handlebars.registerHelper 'linkChannels', (content) ->
  content = content.replace(/(#)([a-zA-Z0-9]+)(!hear|!local)?/gi, "<a href='/$2$3'>$1$2$3</a>")
  content = content.replace(/(@[a-zA-Z0-9]+)/gi, "<a href='/$1'>$1</a>")

Handlebars.registerHelper 'prettyTimeFromNow', (time) ->
  moment(time).startOf('minute').fromNow(false)

Handlebars.registerHelper 'isoTimestamp', (time) ->
  moment(time).format()

Handlebars.registerHelper 'prettyTimestamp', (time) ->
  moment(time).format('MMM Do, YY')

Handlebars.registerHelper 'pluralize', (string, count, plural) ->
  count = if count then count else 0
  "#{count} #{Humanize.pluralize(count, string, plural)}"

Handlebars.registerHelper 'isAdmin', ->
  Meteor.user() && Meteor.user().slug == 'marc'

Handlebars.registerHelper 'isWeb', ->
  Session.get('platform') == 'Web'

Handlebars.registerHelper 'imageUrl', (imagePath, optionString) ->
  return '' unless imagePath
  if imagePath.match(/http|www|\.com/ig) # is this a full URL?
    imagePath
  else
    Meteor.settings.public.IMAGE_ROOT_URL + (if optionString then "/#{optionString}/" else "") + imagePath

Handlebars.registerHelper 'loggedIn', ->
  Meteor.userId()
