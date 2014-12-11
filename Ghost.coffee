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
  constructor: (directory)->
    if !directory["descript.txt"] then throw new Error("descript.txt not found")
    @directory = directory
    buffer = @directory["descript.txt"]
    descriptTxt = Nar.convert(buffer)
    @descript = Nar.parseDescript(descriptTxt)
    @server = null

  load: ->
    new Promise (resolve, reject) =>
      keys = Object.keys(Ghost.shiories)
      shiori = keys.find (shiori)=> Ghost.shiories[shiori].detect(@directory)
      if !shiori
        return reject(new Error("shiori not found or unknown shiori"))

      if !Ghost.shiories[shiori].worker?
        return reject(new Error("unsupport shiori"))

      [fn, args] = Ghost.shiories[shiori].worker
      imports = (Ghost.shiories[shiori].imports || []).map (src)=> @path + src

      @server = new ServerWorker(fn, args, imports)
      [directory, buffers] = ServerWorker.createTransferable(@directory)

      @server.request "load", directory, buffers, (err, code)->
        if err? then reject err else resolve code

      @directory = null

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
      @server.request "unload", (err, code, dirs) ->
        if err?
        then reject(err)
        else resolve([code, dirs])

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
      reply([error, code])

    self.on "request", (request, reply)->
      try response = shiorihandler.request(request)
      catch error
      reply([error, response])

    self.on "unload", (_, reply)->
      try
        code = shiorihandler.unload()

        # dirs response example
        directory = {"descript.txt": new ArrayBuffer(1)};
        
        [dirs, buffers] = createTransferable(directory)
      catch error
      reply([error, code, dirs], buffers)

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
