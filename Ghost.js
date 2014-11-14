// Generated by CoffeeScript 1.7.1
var Ghost;

Ghost = (function() {
  var Nar, ShioriJK, Worker;

  Nar = window["Nar"];

  ShioriJK = window["ShioriJK"];

  Worker = window["Worker"];

  function Ghost(tree) {
    if (!tree["descript.txt"]) {
      throw new Error("descript.txt not found");
    }
    this.tree = tree;
    this.descript = Nar.parseDescript(Nar.convert(this.tree["descript.txt"].asArrayBuffer()));
    this.worker = null;
  }

  Ghost.prototype.load = function(callback) {
    var buffers, directory, _ref;
    if (!this.descript["shiori"]) {
      return callback(new Error("shiori not found"));
    }
    if (!this.tree[this.descript["shiori"]]) {
      return callback(new Error("shiori not found"));
    }
    switch (Ghost.detectShiori(this.tree[this.descript["shiori"]].asArrayBuffer())) {
      case "satori":
        return callback(new Error("unsupport shiori"));
      case "kawari":
        return callback(new Error("unsupport shiori"));
      case "yaya":
        return callback(new Error("unsupport shiori"));
      case "kawari":
        return callback(new Error("unsupport shiori"));
      case "miyojs":
        this.worker = new Worker("./ShioriWorker-MiyoJS.js");
        break;
      default:
        return callback(new Error("cannot detect shiori type: " + this.descript["shiori"]));
    }
    console.log((_ref = Ghost.createTransferable(this.tree), directory = _ref.directory, buffers = _ref.buffers, _ref));
    this.worker.postMessage({
      event: "load",
      data: directory
    }, buffers);
    this.worker.onmessage = function(_arg) {
      var error, event, _ref1;
      _ref1 = _arg.data, event = _ref1.event, error = _ref1.error;
      if (event === "loaded") {
        return callback(error);
      }
    };
    return void 0;
  };

  Ghost.prototype.request = function(request, callback) {
    this.worker.postMessage({
      event: "request",
      data: request
    });
    this.worker.onmessage = function(_arg) {
      var error, event, response, _ref;
      _ref = _arg.data, event = _ref.event, error = _ref.error, response = _ref.data;
      if (event === "response") {
        return callback(error, response);
      }
    };
    return void 0;
  };

  Ghost.prototype.unload = function(callback) {
    this.worker.postMessage({
      event: "unload"
    });
    this.worker.onmessage = function(_arg) {
      var error, event, _ref;
      _ref = _arg.data, event = _ref.event, error = _ref.error;
      if (event === "unloaded") {
        return callback(error);
      }
    };
    return void 0;
  };

  Ghost.detectShiori = function(buffer) {
    return "miyojs";
  };

  Ghost.createTransferable = function(tree) {
    return Object.keys(tree).reduce((function(_arg, filename) {
      var buffer, buffers, directory;
      directory = _arg.directory, buffers = _arg.buffers;
      if (!!tree[filename] && tree[filename].dir instanceof Boolean) {
        console.log(tree[filename]);
        buffer = tree[filename].asArrayBuffer();
        buffers.push(buffer);
        directory[filename] = buffer;
      }
      return {
        directory: directory,
        buffers: buffers
      };
    }), {
      directory: {},
      buffers: []
    });
  };

  Ghost.createRequest = function(method, event) {
    var request;
    request = new ShioriJK.Message.Request();
    request.request_line.method = method;
    request.request_line.protocol = "SHIORI";
    request.request_line.version = "3.0";
    Object.keys(event).forEach(function(key) {
      return request.headers.set(key, ev[key]);
    });
    return "" + request;
  };

  Ghost.parseResponse = function(response) {
    response = new ShioriJK.Shiori.Response.Parser();
    response.parse(response);
    return response;
  };

  return Ghost;

})();
