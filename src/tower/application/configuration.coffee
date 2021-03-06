Tower.Support.Object.extend Tower, 
  env:        "development"
  port:       3000
  version:    "0.3.0"
  client:     typeof(window) != "undefined"
  root:       "/"
  publicPath: "/"
  case:       "camelcase"
  namespace:  null
  accessors:  typeof(window) == "undefined"
  logger:     if typeof(_console) != 'undefined' then _console else console
  structure:  "standard"
  config:     {}
  namespaces: {}
  metadata:   {}
  metadataFor: (name) ->
    @metadata[name] ||= {}
  
  sync: (method, records, callback) ->
    callback null, records if callback
  
  get: ->
    Tower.request "get", arguments...

  post: ->
    Tower.request "post", arguments...

  put: ->
    Tower.request "put", arguments...

  destroy: ->
    Tower.request "delete", arguments...
  
  request: (method, path, options, callback) ->
    if typeof options == "function"
      callback      = options
      options       = {}
    options       ||= {}
    url             = path
    location        = new Tower.Dispatch.Url(url)
    request         = new Tower.Dispatch.Request(url: url, location: location, method: method)
    response        = new Tower.Dispatch.Response(url: url, location: location, method: method)
    request.query   = location.params
    Tower.Application.instance().handle request, response, ->
      callback.call @, @response
      
  raise: ->
    throw new Error(Tower.t(arguments...))
  
  t: ->
    Tower.Support.I18n.translate(arguments...)
    
  l: ->
    Tower.Support.I18n.localize(arguments...)
  
  stringify: ->
    string = Tower.Support.Array.args(arguments).join("_")
    switch Tower.case
      when "snakecase"
        Tower.Support.String.underscore(string)
      else
        Tower.Support.String.camelcase(string)
        
  namespace:  ->
    Tower.Application.instance().constructor.name
    
  module: (namespace) ->
    node    = Tower.namespaces[namespace]
    return node if node
    parts   = namespace.split(".")
    node    = Tower
    
    for part in parts
      node  = node[part] ||= {}
    
    Tower.namespaces[namespace] = node
  
  constant: (string) ->
    node  = global
    parts = string.split(".")
    
    try
      for part in parts
        node = node[part]
    catch error
      # try doing namespace version as last resort
      node = null
    unless node
      namespace = Tower.namespace()
      if namespace && parts[0] != namespace
        node = Tower.constant("#{namespace}.#{string}")
      else
        throw new Error("Constant '#{string}' wasn't found")
    node
    
  namespaced: (string) ->
    namespace = Tower.namespace()
    if namespace
      "#{namespace}.#{string}"
    else
      string
      
  async: (array, iterator, callback) ->
    return callback() unless array.length
    completed = 0
    iterate = ->
      iterator array[completed], (error) ->
        if error
          callback error
          callback = ->
        else
          completed += 1
          if completed == array.length
            callback()
          else
            iterate()

    iterate()

