// Generated by CoffeeScript 1.8.0
var shiori, shiorihandler;

self.importScripts("encoding.min.js");

self.importScripts("libsatori.js");

self.importScripts("nativeshiori.js");

shiori = new Satori();

shiori.Module.logReadFiles = true;

shiorihandler = null;

self.onmessage = function(_arg) {
  var code, data, event, filepath, filestr, request, response, uint8arr, _ref;
  _ref = _arg.data, event = _ref.event, data = _ref.data;
  switch (event) {
    case "load":
      for (filepath in data) {
        if (/\bsatori_conf\.txt$/.test(filepath)) {
          uint8arr = new Uint8Array(data[filepath]);
          filestr = Encoding.codeToString(Encoding.convert(uint8arr, 'UNICODE', 'SJIS'));
          if (/＠SAORI/.test(filestr)) {
            filestr = filestr.replace(/＠SAORI/, '＠NO__SAORI');
            data[filepath] = new Uint8Array(Encoding.convert(Encoding.stringToCode(filestr), 'SJIS', 'UNICODE'));
            console.log('REMOVE ＠SAORI');
          }
          break;
        }
      }
      shiorihandler = new NativeShiori(shiori, data, true);
      code = shiorihandler.load('/home/web_user/');
      return self.postMessage({
        event: "loaded",
        error: null,
        data: code
      });
    case "request":
      request = data;
      response = shiorihandler.request(request);
      return self.postMessage({
        event: "response",
        error: null,
        data: response
      });
    case "unload":
      code = shiorihandler.unload();
      return self.postMessage({
        event: "unloaded",
        error: null,
        data: code
      });
    default:
      throw new Error(event + " event not support");
  }
};
