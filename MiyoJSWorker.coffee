
self.importScripts("node_modules/ikagaka.nar.js/node_modules/encoding-japanese/encoding.js")
self.importScripts("node_modules/shiorijk/lib/shiorijk.js")
self.importScripts("node_modules/miyojs-filter-autotalks/autotalks.js")
self.importScripts("node_modules/miyojs-filter-default_response_headers/default_response_headers.js")
self.importScripts("node_modules/miyojs-filter-property/property.js")
self.importScripts("node_modules/miyojs-filter-variables/variables.js")
self.importScripts("node_modules/miyojs-filter-value_filters/value_filters.js")
self.importScripts("node_modules/miyojs/node_modules/js-yaml/dist/js-yaml.min.js")
self.importScripts("node_modules/miyojs/lib/miyo.js")

shiori = null

self.onmessage = ({data: {event, data}})->
  switch event
    when "load"
      directory = data
      dictionary = Object
        .keys(directory)
        .filter((filepath)-> /^dictionaries\/[^/]+$/.test(filepath))
        .reduce(((dictionary, filepath)->
          uint8Arr = new Uint8Array(directory[filepath])
          tabIndentedYaml = Encoding.codeToString(Encoding.convert(uint8Arr, 'UNICODE', 'AUTO'))
          yaml = tabIndentedYaml.replace(/\t/g, ' ')
          dic = jsyaml.safeLoad (yaml)
          Miyo.DictionaryLoader.merge_dictionary(dic, dictionary)
          dictionary
        ), {})
      shiori = new Miyo(dictionary)
      shiori.load({})
      console.log shiori
      self.postMessage({"event": "loaded",   "error": null})
    when "request"
      requestTxt = data
      paser = new ShioriJK.Shiori.Request.Parser()
      request = paser.parse(requestTxt)
      console.log request
      response = shiori.request(request)
      console.log response
      responseTxt = ""+response
      self.postMessage({event: "response", error: null, data: responseTxt})
    when "unload"
      shiori.unload()
      self.postMessage({event: "unloaded", error: null})
    else throw new Error(event + " event not support")
