@slugify = (text) ->
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '');            # Trim - from end of text

@hashify = (text) ->
  # capitalize first letter of each word
  text = text.replace(/\w\S*/g, (txt) -> txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase())
  text.toString().toLowerCase()
    .replace(/\s+/g, '')           # Replace spaces with nothing
    .replace(/[^\w]+/g, '')       # Remove all non-word chars
