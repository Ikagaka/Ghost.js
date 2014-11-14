
self.importScripts("node_modules/ikagaka.nar.js/node_modules/encoding-japanese/encoding.js")
self.importScripts("node_modules/shiorijk/lib/shiorijk.js")
self.importScripts("node_modules/miyojs-filter-autotalks/autotalks.js")
self.importScripts("node_modules/miyojs-filter-default_response_headers/default_response_headers.js")
self.importScripts("node_modules/miyojs-filter-property/property.js")
self.importScripts("node_modules/miyojs-filter-variables/variables.js")
self.importScripts("node_modules/miyojs-filter-value_filters/value_filters.js")
self.importScripts("node_modules/miyojs/node_modules/js-yaml/dist/js-yaml.min.js")
self.importScripts("node_modules/miyojs/lib/miyo.js")


directory = null
dictionary = null
shiori = null

self.onmessage = ({data: {event, data}})->
  switch event
    when "load"
      directory = data
      dictionary = Object.keys(directory["dictionaries"]).reduce(((dictionary, filename)->
        if directory["dictionaries"][filename] instanceof ArrayBuffer
          yaml = Encoding.codeToString(Encoding.convert(new Uint8Array(directory["dictionaries"][filename]), 'UNICODE', 'AUTO')).replace(/\t/g, ' ')
          try
            dic = jsyaml.safeLoad (yaml)
            Miyo.DictionaryLoader.merge_dictionary(dic, dictionary)
          catch err
            console.log err
        dictionary
      ), {})
      console.log dictionary
      shiori = new Miyo(dictionary)
      shiori.load({})
      console.log shiori
      self.postMessage({"event": "loaded",   "error": null})
    when "request"
      requestTxt = data
      paser = new ShioriJK.Shiori.Request.Parser()
      request = paser.parse(requestTxt)
      console.log request.request_line.version
      console.log request
      response = shiori.request(request)
      console.log response
      responseTxt = ""+response
      self.postMessage({event: "response", error: null, data: responseTxt})
    when "unload"
      shiori.unload()
      self.postMessage({event: "unloaded", error: null})
    else throw new Error(event + " event not support")
