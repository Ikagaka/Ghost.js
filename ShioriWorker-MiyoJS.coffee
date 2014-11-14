

self.importScripts("node_modules/shiorijk/lib/shiorijk.js")
self.importScripts("node_modules/miyojs/lib/miyo.js")

class Shiori
  constructor: ->
    @directory = null
  load: (@directory, callback)->
    setTimeout -> callback(null)
  request: (request, callback)->
    setTimeout -> callback(null, "hello")
  unload: (callback)->
    setTimeout -> callback(null)

shiori = new Shiori()

self.onmessage = ({data: {event, data}})->
  switch event
    when "load"    then shiori.load    data, (err)->           self.postMessage({event: "loaded",   error: err})
    when "request" then shiori.request data, (err, response)-> self.postMessage({event: "response", error: err, data: response})
    when "unload"  then shiori.unload        (err)->           self.postMessage({event: "unloaded", error: err})
