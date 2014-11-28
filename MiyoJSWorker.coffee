self.importScripts("encoding.min.js")
self.importScripts("shiorijk.js")
self.importScripts("browserfs.js")
self.importScripts("ikagaka.nar.js")
self.importScripts("simple-ini.js")
Nar = @Nar || @Ikagaka.Nar

BrowserFS.install @
fsb = new BrowserFS.FileSystem.InMemory()
BrowserFS.initialize(fsb)

class MiyoShioriWorker
	constructor: (@storage) ->
	load: (dirpath) ->
		if @storage?
			@_load_fs dirpath
		shiori = (Nar.parseDescript Nar.convert @storage["descript.txt"]).shiori
		ini = shiori['SHIOLINK.INI'] || shiori['SHIOLINK.ini'] || shiori['shiolink.ini'] || shiori['shiolink.INI']
		unless ini
			throw 'only SHIOLINK.INI support is available'
		sini = new SimpleIni -> Encoding.codeToString(Encoding.convert(ini, 'UNICODE', 'AUTO'))
		unless sini.hasSection 'SHIOLINK'
			throw 'SHIOLINK.INI has no SHIOLINK section'
		cmd = sini.get 'SHIOLINK.commandline'
		dir = (cmd.split /\s*/)[2] || '.'
		Miyo = require 'miyojs'
		@shiori = new Miyo Miyo.DictionaryLoader.load_recursive dir
		@shiori.load dirpath
	_load_fs: (base_directory) ->
		fs = require 'fs'
		path = require 'path'
		for filepath in @storage
			dirname = path.dirname filepath
			dir = path.join base_directory, dirname
			try
				fs.statSync dir
			catch
				@_mkpath dir
			if ! /\/$/.test(filepath)
				content = new Uint8Array(@storage[filepath])
				file = path.join base_directory, filepath
				fs.writeFileSync file, content, {encoding: 'binary'}
	_mkpath: (dir) ->
		fs = require 'fs'
		path = require 'path'
		mkdir = (dir) ->
			try
				fs.statSync dir
			catch
				mkdir payh.dirname dir
				fs.mkdirSync dir
		mkdir dir
		return true

self.onmessage = ({data: {event, data}})->
	switch event
		when "load"
			directory = data
			dictionary = Object
				.keys(directory)
				.filter((filepath)-> /^dictionaries\/[^/]+$/.test(filepath))
				.reduce(((dictionary, filepath)->
					uint8Arr = new Uint8Array(directory[filepath])
					tabIndentedYaml = Encoding.codeToString(Encoding.convert(uint8Arr, 'UNICODE', 'AUTO'))
					yaml = tabIndentedYaml.replace(/\t/g, ' ')
					dic = jsyaml.safeLoad (yaml)
					Miyo.DictionaryLoader.merge_dictionary(dic, dictionary)
					dictionary
				), {})
			shiori = new Miyo(dictionary)
			console.log(Object.keys(dictionary).join(' '))
			shiori.load('')
			.then ->
				self.postMessage({"event": "loaded",	 "error": null})
			.catch (error) ->
				console.warn(error)
		when "request"
			requestTxt = data
			parser = new ShioriJK.Shiori.Request.Parser()
			request = parser.parse(requestTxt)
			#console.log(request)
			shiori.request(request)
			.then (response) ->
				self.postMessage({event: "response", error: null, data: '' + response})
			.catch (error) ->
				console.warn(error)
		when "unload"
			shiori.unload()
			.then ->
				self.postMessage({event: "unloaded", error: null})
			.catch (error) ->
				console.warn(error)
		else throw new Error(event + " event not support")
