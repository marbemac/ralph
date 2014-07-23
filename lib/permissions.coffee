# check that the userId specified owns the documents
@ownsDocument = (userId, doc) ->
  doc && doc.userId == userId
