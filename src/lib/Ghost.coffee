class Ghost

  @shiori_detectors = []
  @shiories = {}

  constructor: (@fs)->
    for shiori_detector in Ghost.shiori_detectors
      if shiori_detector.detect(@fs)
        shiori_name = shiori_detector.name
        break
    unless shiori_name? then throw new Error("shiori not found or unknown shiori")
    @shiori = new Ghost.shiories[shiori_name](@fs)

  load: ->
    new Promise (resolve, reject) =>
      resolve @shiori.load @dirpath

  request: (request)->
    new Promise (resolve, reject) =>
      resolve @shiori.request request

  unload: ->
    new Promise (resolve, reject) =>
      resolve @shiori.unload()

if module?.exports?
  module.exports = Ghost
else if @Ikagaka?
  @Ikagaka.Ghost = Ghost
else
  @Ghost = Ghost
