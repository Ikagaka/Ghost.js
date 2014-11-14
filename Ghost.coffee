

class Ghost
  _ = window["_"]
  Nar = window["Nar"]
  Worker = window["Worker"]

  constructor: (directory)->
    console.log directory
    if !directory["descript.txt"] then throw new Error("descript.txt not found")
    @directory = directory
    buffer = @directory["descript.txt"].asArrayBuffer()
    descriptTxt = Nar.convert(buffer)
    @descript = Nar.parseDescript(descriptTxt)
    @worker = null

  load: (callback)->
    if !@descript["shiori"]        then return callback(new Error("shiori not found"))
    if !@directory[@descript["shiori"]] then return callback(new Error("shiori not found"))
    switch Ghost.detectShiori(@directory[@descript["shiori"]].asArrayBuffer())
      when "satori" then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "yaya"   then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "miyojs" then @worker = new Worker("./MiyoJSWorker.js")
      else return callback(new Error("cannot detect shiori type: "+ @descript["shiori"]))
    {directory, buffers} = Ghost.createTransferable(@directory)
    @worker.postMessage({event: "load", data: directory}, buffers)
    @worker.onmessage = ({data: {event, error}})->
      if event is "loaded" then callback(error)
    undefined

  request: (request, callback)->
    @worker.postMessage({event: "request", data: request})
    @worker.onmessage = ({data:{event, error, data: response}})->
      if event is "response" then callback(error, response)
    undefined

  unload: (callback)->
    @worker.postMessage({event: "unload"})
    @worker.onmessage = ({data: {event, error}})->
      if event is "unloaded" then callback(error)
    undefined

  @detectShiori = (buffer)->
    "miyojs"

  @createTransferable: (_directory)->
    Object.keys(_directory)
      .reduce((({directory, buffers}, filename)->
        buffer = _directory[filename].asArrayBuffer()
        directory[filename] = buffer
        buffers.push(buffer)
        {directory, buffers}
      ), {directory: {}, buffers: []})
