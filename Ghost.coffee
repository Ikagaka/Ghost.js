Nar    = @Nar || @Ikagaka.Nar || require("ikagaka.nar.js")
Worker = @Worker

class Ghost

  constructor: (directory)->
    if !directory["descript.txt"] then throw new Error("descript.txt not found")
    @directory = directory
    buffer = @directory["descript.txt"].asArrayBuffer()
    descriptTxt = Nar.convert(buffer)
    @descript = Nar.parseDescript(descriptTxt)
    @worker = null

  load: (callback)->
    if !@directory[@descript["shiori"]] and !@directory["shiori.dll"]
      setTimeout -> callback(new Error("shiori not found"))
      return
    keys = Object.keys(Ghost.shiories)
    shiori = keys.find (shiori)=> Ghost.shiories[shiori].detect(@directory)
    if !shiori
      setTimeout -> callback(new Error("unkown shiori"))
      return
    if typeof Ghost.shiories[shiori].worker? is "undefined"
      setTimeout -> callback(new Error("unsupport shiori"))
      return
    [fn, args] = Ghost.shiories[shiori].worker
    imports = (Ghost.shiories[shiori].imports || []).map (src)=> @path + src
    @worker = Ghost.createWorker(fn, args, imports)
    {directory, buffers} = Ghost.createTransferable(@directory)
    @worker.addEventListener "error", (ev)-> console.error(ev.error?.stack || ev.error || ev)
    @worker.postMessage({event: "load", data: directory}, buffers)
    delete @directory # g.c.
    @worker.onmessage = ({data: {event, error}})->
      if event is "loaded" then callback(error)
    return

  request: (request, callback)->
    if @logging then console.log(request)
    @worker.postMessage({event: "request", data: request})
    @worker.onmessage = ({data:{event, error, data: response}})=>
      if @logging then console.log(response)
      if event is "response" then callback(error, response)
    return

  unload: (callback)->
    @worker.postMessage({event: "unload"})
    @worker.onmessage = ({data: {event, error}})->
      if event is "unloaded" then callback(error)
    return

  path: location.protocol + "//" + location.host + location.pathname.split("/").reverse().slice(1).reverse().join("/") + "/"

  logging: false

  @nativeShioriWorkerScript = (CONSTRUCTOR_NAME)->
    shiori = new self[CONSTRUCTOR_NAME]()
    shiori.Module.logReadFiles = true

    shiorihandler = null
    self.onmessage = ({data: {event, data}})->
      error = null
      switch event
        when "load"
          if CONSTRUCTOR_NAME is "Satori" then data = prepareSatori(data)
          directorys = data
          shiorihandler = new NativeShiori(shiori, directorys, true)
          try code = shiorihandler.load('/home/web_user/')
          catch error
          self.postMessage({event: "loaded", error, data: code})
        when "request"
          request = data
          try response = shiorihandler.request(request)
          catch error
          self.postMessage({event: "response", error, data: response})
        when "unload"
          try code = shiorihandler.unload()
          catch error
          self.postMessage({event: "unloaded", error, data: code})
        else throw new Error(event + " event not support")

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
      worker: [Ghost.nativeShioriWorkerScript, ["Kawari7Shiori"]]
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

  @createWorker = (fn, args, imports=[])->

    new Worker(
      URL.createObjectURL(
        new Blob(
          [imports.map((src)->"importScripts('#{src}');\n").join("")
           "(#{fn})(#{args.map(JSON.stringify).join(",")});"],
          {type:"text/javascript"})))

  @createTransferable: (_directory)->
    Object.keys(_directory)
      .filter((filepath)-> !!filepath)
      .reduce((({directory, buffers}, filepath)->
        buffer = _directory[filepath].asArrayBuffer()
        directory[filepath] = buffer
        buffers.push(buffer)
        {directory, buffers}
      ), {directory: {}, buffers: []})



if module?.exports?
  module.exports = Ghost
else if @Ikagaka?
  @Ikagaka.Ghost = Ghost
else
  @Ghost = Ghost
