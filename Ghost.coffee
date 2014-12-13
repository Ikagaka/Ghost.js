Nar    = @Nar || @Ikagaka.Nar || require("ikagaka.nar.js")
Worker = @Worker

class ServerWorker
  constructor: (fn, args, imports=[])->
    @url = URL.createObjectURL(
      new Blob([
        imports.map((src)-> "importScripts('#{src}');\n").join("") + "\n"
        "(#{ServerWorker.Server})();\n"
        "var createTransferable = #{ServerWorker.createTransferable};\n"
        "(#{fn})(#{args.map(JSON.stringify).join(",")});"
      ], {type:"text/javascript"}))
    @worker = new Worker(@url)
    @worker.addEventListener "error", (ev)->
      console.error(ev.error?.stack || ev.error || ev)
    @worker.addEventListener "message", ({data: [id, args]})=>
      @callbacks[id](args...)
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
        reply = (args, transferable)->
          self.postMessage([id, args], transferable)
        handlers[event](data, reply)
        return
      self.on = (event, callback)->
        handlers[event] = callback
        return
  @createTransferable: (dic)->
    keys = Object.keys(dic)
    hits = keys.filter((filepath)-> !!filepath)
    hits.reduce((([_dic, buffers], key)->
      buffer = dic[key]
      _dic[key] = buffer
      buffers.push(buffer)
      [_dic, buffers]
    ), [{}, []])

class Ghost
  constructor: (@dirpath, directory, path='')->
    if !directory["descript.txt"] then throw new Error("descript.txt not found")
    @directory = directory
    buffer = @directory["descript.txt"]
    descriptTxt = Nar.convert(buffer)
    @descript = Nar.parseDescript(descriptTxt)
    shiori = Object.keys(Ghost.shiories).find (shiori)=> Ghost.shiories[shiori].detect(@directory)
    if !shiori
      throw new Error("shiori not found or unknown shiori")
    if !Ghost.shiories[shiori].worker?
      throw new Error("unsupport shiori")
    [fn, args] = Ghost.shiories[shiori].worker
    imports = (Ghost.shiories[shiori].imports || []).map (src)=> @path + path + src
    @server = new ServerWorker(fn, args, imports)

  push: ->
    new Promise (resolve, reject) =>
      [directory, buffers] = ServerWorker.createTransferable(@directory)
      @server.request "push", [@dirpath, directory], buffers, (err)->
        if err? then reject err else resolve()
      @directory = null

  load: ->
    new Promise (resolve, reject) =>
      @server.request "load", @dirpath, (err, code)->
        if err? then reject err else resolve code

  request: (request)->
    new Promise (resolve, reject) =>
      console.log(request) if @logging
      @server.request "request", request, (err, response)=>
        if err?
          reject err
        else
          console.log(response) if @logging
          resolve response

  unload: ->
    new Promise (resolve, reject) =>
      @server.request "unload", (err, code) ->
        if err?  then reject(err) else resolve(code)

  pull: ->
    new Promise (resolve, reject) =>
      @server.request "pull", @dirpath, (err, dirs) ->
        if err?  then reject(err) else resolve(dirs)

  path: location.protocol + "//" + location.host + location.pathname.split("/").reverse().slice(1).reverse().join("/") + "/"

  logging: false

  @nativeShioriWorkerScript = (CONSTRUCTOR_NAME)->
    shiori = new self[CONSTRUCTOR_NAME]()
    shiori.Module.logReadFiles = true
    shiorihandler = new NativeShiori(shiori, true)

    self.on "push", ([dirpath, dirs], reply)->
      dirs = prepareSatori(dirs) if CONSTRUCTOR_NAME is "Satori"
      try
        shiorihandler.push(dirpath, dirs)
      catch error
      reply([error?.stack])

    self.on "load", (dirpath, reply)->
      try
        code = shiorihandler.load(dirpath)
      catch error
      reply([error?.stack, code])

    self.on "request", (request, reply)->
      try response = shiorihandler.request(request)
      catch error
      reply([error?.stack, response])

    self.on "unload", (_, reply)->
      try
        code = shiorihandler.unload()
      catch error
      reply([error?.stack, code])

    self.on "pull", (dirpath, reply)->
      try
        directory = shiorihandler.pull(dirpath)
        [dirs, buffers] = createTransferable(directory)
      catch error
      reply([error?.stack, dirs], buffers)

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


  @ServerWorker = ServerWorker



if module?.exports?
  module.exports = Ghost
else if @Ikagaka?
  @Ikagaka.Ghost = Ghost
else
  @Ghost = Ghost
