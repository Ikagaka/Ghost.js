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
      code = shiorihandler.load('/home/web_user/')
      self.postMessage({event: "loaded", error: null, data: code})
    when "request"
      request = data
      response = shiorihandler.request(request)
      self.postMessage({event: "response", error: null, data: response})
    when "unload"
      code = shiorihandler.unload()
      self.postMessage({event: "unloaded", error: null, data: code})
    else throw new Error(event + " event not support")
