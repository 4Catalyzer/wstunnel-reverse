// Generated by CoffeeScript 1.8.0
(function() {
  var ChainedWebApps, HttpTunnelReq, HttpTunnelServer, WebSocketServer, WsIdStream, bindStream, http, log, net, parseAddress, url, wst_server;

  WebSocketServer = require('websocket').server;

  http = require('http');

  url = require("url");

  net = require("net");

  WsIdStream = require("./WsIdStream");

  log = require("lawg");

  HttpTunnelServer = require("./httptunnel/Server");

  HttpTunnelReq = require("./httptunnel/ConnRequest");

  ChainedWebApps = require("./ChainedWebApps");

  bindStream = require("./bindStream");

  parseAddress = require('./utils').parseAddress;

  module.exports = wst_server = (function() {
    wst_server.prototype.counter = 0;

    function wst_server(webapp) {
      var apps;
      this.httpServer = http.createServer();
      this.wsServer = new WebSocketServer({
        httpServer: this.httpServer,
        autoAcceptConnections: false
      });
      apps = new ChainedWebApps();
      this.tunnServer = new HttpTunnelServer(apps);
      if (webapp) {
        apps.setDefaultApp(webapp);
      }
      apps.bindToHttpServer(this.httpServer);
    }

    wst_server.prototype.start = function(localAddr, cb) {
      var host, port, _ref;
      _ref = parseAddress(localAddr), host = _ref.host, port = _ref.port;
      return this.httpServer.listen(port, host, (function(_this) {
        return function(err) {
          if (cb) {
            cb(err);
          }
          return _this.wsServer.on('request', function(request) {
            var httpRequest, tcpServer, tunnelPort, wsConn;
            wsConn = request.accept('tunnel-protocol', request.origin);
            httpRequest = request.httpRequest;
            tunnelPort = url.parse(httpRequest.url, true).query.port;
            tcpServer = net.createServer();
            tcpServer.listen(tunnelPort);
            tcpServer.on("connection", function(tcpConn) {
              var wsStream;
              wsStream = new WsIdStream(wsConn, _this.counter++);
              return bindStream(tcpConn, wsStream);
            });
            wsConn.on('close', function() {
              log("websocket closed");
              return tcpServer.close(function() {
                return log("tcpServer closed");
              });
            });
            return log("opened a new tunnel entrance at " + tunnelPort);
          });
        };
      })(this));
    };

    return wst_server;

  })();

}).call(this);

//# sourceMappingURL=WstReverseServer.js.map