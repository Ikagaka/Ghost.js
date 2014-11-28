self.importScripts("encoding.min.js")
self.importScripts("libsatori.js")
self.importScripts("nativeshiori.js")

shiori = new Satori()
shiori.Module.logReadFiles = true

shiorihandler = null
self.onmessage = ({data: {event, data}})->
  switch event
    when "load"
      for filepath of data
        if /\bsatori_conf\.txt$/.test(filepath)
          uint8arr = new Uint8Array(data[filepath])
          filestr = Encoding.codeToString(Encoding.convert(uint8arr, 'UNICODE', 'SJIS'))
          if /＠SAORI/.test(filestr)
            filestr = filestr.replace(/＠SAORI/, '＠NO__SAORI')
            data[filepath] = new Uint8Array(Encoding.convert(Encoding.stringToCode(filestr), 'SJIS', 'UNICODE'))
            console.log('REMOVE ＠SAORI')
          break
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
