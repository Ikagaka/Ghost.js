Nar    = @Nar || @Ikagaka.Nar || require("ikagaka.nar.js")
Worker = @Worker

class ServerWorker
  constructor: (fn, args, imports=[])->
    @url = URL.createObjectURL(
      new Blob([
        imports.map((src)-> "importScripts('#{src}');\n").join("") + "\n"
        "(#{ServerWorker.Server})();\n"
        "(#{fn})(#{args.map(JSON.stringify).join(",")});"
      ], {type:"text/javascript"}))
    @worker = new Worker(@url)
    @worker.addEventListener "error", (ev)->
      console.error(ev.error?.stack || ev.error || ev)
    @worker.addEventListener "message", ({data: [id, args]})=>
      @callbacks[id].apply(null, args)
      delete @callbacks[id]
    @requestId = 0
    @callbacks = {}
  request: (event, [data, transferable]..., callback)->
    id = @requestId++
    @callbacks[id] = callback
    @worker.postMessage([id, event, data], transferable)
  terminate: ->
    @worker.terminate()
    URL.revokeObjectURL(@url)
  @Server = ->
    do ->
      handlers = {}
      self.addEventListener "message", ({data: [id, event, data]})->
        handlers[event] data, ->
          self.postMessage([id, [].slice.call(arguments)])
        return
      self.on = (event, callback)->
        handlers[event] = callback
        return

class Ghost
  constructor: (directory)->
    if !directory["descript.txt"] then throw new Error("descript.txt not found")
    @directory = directory
    buffer = @directory["descript.txt"]
    descriptTxt = Nar.convert(buffer)
    @descript = Nar.parseDescript(descriptTxt)
    @server = null

  load: (callback)->
    if !@directory[@descript["shiori"]] and !@directory["shiori.dll"]
      setTimeout(callback.bind(null, new Error("shiori not found"))); return

    keys = Object.keys(Ghost.shiories)
    shiori = keys.find (shiori)=> Ghost.shiories[shiori].detect(@directory)
    if !shiori
      setTimeout(callback.bind(null, new Error("unkown shiori"))); return

    if !Ghost.shiories[shiori].worker?
      setTimeout(callback.bind(null, new Error("unsupport shiori"))); return

    [fn, args] = Ghost.shiories[shiori].worker
    imports = (Ghost.shiories[shiori].imports || []).map (src)=> @path + src

    @server = new ServerWorker(fn, args, imports)
    [directory, buffers] = Ghost.createTransferable(@directory)

    @server.request "load", directory, buffers, (err, code)->
      callback(err, code)

    @directory = null
    return

  request: (request, callback)->
    console.log(request) if @logging
    @server.request "request", request, (err, response)=>
      console.log(response) if @logging
      callback(err, response)
    return

  unload: (callback)->
    @server.request "unload", (err, code)-> callback(err, code)
    return

  path: location.protocol + "//" + location.host + location.pathname.split("/").reverse().slice(1).reverse().join("/") + "/"

  logging: false

  @nativeShioriWorkerScript = (CONSTRUCTOR_NAME)->
    shiori = new self[CONSTRUCTOR_NAME]()
    shiori.Module.logReadFiles = true
    shiorihandler = null

    self.on "load", (dirs, reply)->
      dirs = prepareSatori(dirs) if CONSTRUCTOR_NAME is "Satori"
      shiorihandler = new NativeShiori(shiori, dirs, true)
      try code = shiorihandler.load('/home/web_user/')
      catch error
      reply(error, code)

    self.on "request", (request, reply)->
      try response = shiorihandler.request(request)
      catch error
      reply(error, response)

    self.on "unload", (_, reply)->
      try code = shiorihandler.unload()
      catch error
      reply(error, code)

    prepareSatori = (data)->
      for filepath of data
        if /\bsatori_conf\.txt$/.test(filepath)
          uint8arr = new Uint8Array(data[filepath])
          filestr = Encoding.codeToString(Encoding.convert(uint8arr, 'UNICODE', 'SJIS'))
          if /＠SAORI/.test(filestr)
            filestr = filestr.replace(/＠SAORI/, '＠NO__SAORI')
            data[filepath] = new Uint8Array(Encoding.convert(Encoding.stringToCode(filestr), 'SJIS', 'UNICODE'))
          break
      return data

  @shiories =
    kawari:
      detect: (dir)-> !!dir["kawarirc.kis"]
      imports: ["encoding.min.js", "nativeshiori.js", "kawari.js"]
      worker: [Ghost.nativeShioriWorkerScript, ["Kawari"]]
    kawari7:
      detect: (dir)-> !!dir["kawari.ini"] # no kis and ini
      imports: ["encoding.min.js", "nativeshiori.js", "kawari7.js"]
      worker: [Ghost.nativeShioriWorkerScript, ["Kawari7"]]
    satori:
      detect: (dir)-> !!dir["satori.dll"]
      imports: ["encoding.min.js", "nativeshiori.js", "libsatori.js"]
      worker: [Ghost.nativeShioriWorkerScript, ["Satori"]]
    yaya:
      detect: (dir)-> !!dir["yaya.dll"]
      imports: ["encoding.min.js", "nativeshiori.js", "yaya.js"]
      worker: [Ghost.nativeShioriWorkerScript, ["YAYA"]]
    aya5:
      detect: (dir)-> !!dir["aya5.dll"]
      imports: ["encoding.min.js", "nativeshiori.js", "aya5.js"]
      worker: [Ghost.nativeShioriWorkerScript, ["AYA5"]]
    aya:
      detect: (dir)-> !!dir["aya.dll"]
    miyojs:
      detect: (dir)-> !!dir["node.exe"]
    misaka:
      detect: (dir)-> !!dir["misaka.dll"]

  @createTransferable: (dic)->
    keys = Object.keys(dic)
    hits = keys.filter((filepath)-> !!filepath)
    hits.reduce((([_dic, buffers], key)->
      buffer = dic[key]
      _dic[key] = buffer
      buffers.push(buffer)
      [_dic, buffers]
    ), [{}, []])

  @ServerWorker = ServerWorker



if module?.exports?
  module.exports = Ghost
else if @Ikagaka?
  @Ikagaka.Ghost = Ghost
else
  @Ghost = Ghost
