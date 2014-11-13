

class Ghost

  Nar = window["Nar"]
  ShioriJK = window["ShioriJK"]

  constructor: (tree)->
    if !tree["descript.txt"] then throw new Error("descript.txt not found")
    @tree = tree
    @descript = Nar.parseDescript(Nar.convert(@tree["descript.txt"].asArrayBuffer()))

  load: (callback)->

  request: (request, callback)->

  unload: (callback)->

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
