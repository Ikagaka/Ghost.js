

class Ghost

  Nar = window["Nar"]
  ShioriJK = window["ShioriJK"]

  constructor: (tree)->
    if !tree["descript.txt"] then throw new Error("descript.txt not found")
    @tree = tree
    @descript = Nar.parseDescript(Nar.convert(@tree["descript.txt"].asArrayBuffer()))
    @shioriWorker = null

  load: (callback)->
    if !@descript["shiori"]        then return callback(new Error("shiori not found"))
    if !@tree[@descript["shiori"]] then return callback(new Error("shiori not found"))
    shiori = @tree[@descript["shiori"]].asArrayBuffer()
    switch @detectShiori(shiori)
      when "satori" then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "yaya"   then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "miyojs" then return @shioriWorker = Ghost.initShioriWorker("miyoJS.js", @tree, callback);
      else               return callback(new Error("cannot detect shiori type"))

  request: (request, callback)->
    @shioriWorker.postMessage({event: "request", request})
    @shioriWorker.onmessage = ({data:{event, error, response}})->
      if event is "response" then callback(error, response)

  unload: (callback)->
    @shioriWorker.postMessage({event: "unload"})
    @shioriWorker.onmessage = ({data:{event, error}})->
      if event is "unloaded" then callback(error)

  @detectShiori = (buffer)->

  @initShioriWorker = (src, tree, callback)->
    worker = new Worker(src)
    {directory, buffers} = Ghost.unzipAll(tree)
    worker.postMessage({event: "load", directory}, buffers)
    worker.onmessage = ({data:{event, error}})->
      if event is "loaded" then callback(error)
    worker

  @unzipAll: (tree)->
    Object.keys(tree).reduce((({directory, buffers}, filename)->
      if !!tree[filename]
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
