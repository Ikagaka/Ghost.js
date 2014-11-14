

class Ghost

  Nar = window["Nar"]
  ShioriJK = window["ShioriJK"]
  Worker = window["Worker"]

  constructor: (tree)->
    if !tree["descript.txt"] then throw new Error("descript.txt not found")
    @tree = tree
    @descript = Nar.parseDescript(Nar.convert(@tree["descript.txt"].asArrayBuffer()))
    @worker = null

  load: (callback)->
    if !@descript["shiori"]        then return callback(new Error("shiori not found"))
    if !@tree[@descript["shiori"]] then return callback(new Error("shiori not found"))
    switch Ghost.detectShiori(@tree[@descript["shiori"]].asArrayBuffer())
      when "satori" then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "yaya"   then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "miyojs" then @worker = new Worker("./ShioriWorker-MiyoJS.js")
      else               return callback(new Error("cannot detect shiori type: "+ @descript["shiori"]))
    console.log {directory, buffers} = Ghost.createTransferable(@tree)
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

  @createTransferable: (tree)->
    Object.keys(tree).reduce((({directory, buffers}, filename)->
      if !!tree[filename] and tree[filename].dir instanceof Boolean
        console.log tree[filename]
        buffer = tree[filename].asArrayBuffer()
        buffers.push(buffer)
        directory[filename] = buffer
      {directory, buffers}
    ), {directory: {}, buffers: []})

  @createRequest = (method, event)->
    request = new ShioriJK.Message.Request()
    request.request_line.method = method
    request.request_line.protocol = "SHIORI"
    request.request_line.version = "3.0"
    Object.keys(event).forEach (key)->
      request.headers.set(key, ev[key])
    ""+request

  @parseResponse = (response)->
    response = new ShioriJK.Shiori.Response.Parser()
    response.parse(response)
    response
