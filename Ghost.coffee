

class Ghost

  Nar = window["Nar"]
  ShioriJK = window["ShioriJK"]

  constructor: (tree)->
    if !tree["descript.txt"] then throw new Error("descript.txt not found")
    @tree = tree
    @descript = Nar.parseDescript(Nar.convert(@tree["descript.txt"].asArrayBuffer()))
    @shiori = null

  load: (callback)->
    if !@descript["shiori"]        then return callback(new Error("shiori not found"))
    if !@tree[@descript["shiori"]] then return callback(new Error("shiori not found"))
    shiori = @tree[@descript["shiori"]].asArrayBuffer()
    switch @detectShiori(shiori)
      when "satori" then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "yaya"   then return callback(new Error("unsupport shiori"))
      when "kawari" then return callback(new Error("unsupport shiori"))
      when "miyojs" then return @shiori = MiyoJS(@tree, callback);
      else               return callback(new Error("cannot detect shiori type"))

  request: (request, callback)->
    @shiori.request(request, callback)

  unload: (callback)->
    @shiori.unload(callback)

  @detectShiori = (buffer)->

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
