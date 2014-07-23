Migrations.add
  version: 1
  name: 'Add ralph feedback channel.'
  up: ->
    ralphFeedbackId = "542fd3a822d71fecf985b99a"
    channelData =
      name: 'Ralph Feedback'
      description: ''
      image: null
    Meteor.call 'createChannel', channelData, 'global', false, 'admin', null, null, null, null, ralphFeedbackId
