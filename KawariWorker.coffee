self.importScripts("encoding.min.js")
self.importScripts("kawari.js")
self.importScripts("nativeshiori.js")

shiori = new Kawari()
shiori.Module.logReadFiles = true

shiorihandler = null
self.onmessage = ({data: {event, data}}) ->
  switch event
    when "load"
      shiorihandler = new NativeShiori(shiori, data, true)
      try code = shiorihandler.load('/home/web_user/')
      catch error
      self.postMessage({event: "loaded", error: error, data: code})
    when "request"
      request = data
      try response = shiorihandler.request(request)
      catch error
      self.postMessage({event: "response", error: error, data: response})
    when "unload"
      try code = shiorihandler.unload()
      catch error
      self.postMessage({event: "unloaded", error: error, data: code})
    else throw new Error(event + " event not support")
