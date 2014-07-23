Accounts.onCreateUser (options, user) ->
  colors = ['#1abc9c','#2ecc71','#3498db','#9b59b6','#34495e','#16a085','#27ae60','#2980b9','#8e44ad','#2c3e50','#e67e22','#e74c3c','#95a5a6','#d35400','#c0392b','#7f8c8d']
  user.slug = slugify(user.username)
  user.chatColor = colors[_.random(colors.length-1)]
  # We still want the default hook's 'profile' behavior.
  if options.profile
    user.profile = options.profile
  user
