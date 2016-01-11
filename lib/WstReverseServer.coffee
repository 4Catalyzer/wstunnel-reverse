WebSocketServer = require('websocket').server;
http = require('http');
url = require("url");
net = require("net");
WsIdStream = require "./WsIdStream"
log = require "lawg"
HttpTunnelServer = require "./httptunnel/Server"
HttpTunnelReq = require "./httptunnel/ConnRequest"
ChainedWebApps = require "./ChainedWebApps"
bindStream = require("./bindStream")
{ parseAddress } = require('./utils')

module.exports = class wst_server

  counter: 0

  # webapp: customize webapp if any, you may use express app
  constructor: (webapp)->
    @httpServer = http.createServer()
    @wsServer = new WebSocketServer(
        httpServer: @httpServer,
        autoAcceptConnections: false
    )
    # each app is http request handler function (req, res, next),  calls next() to ask next app
    # to handle request
    apps = new ChainedWebApps()
    @tunnServer = new HttpTunnelServer(apps)
    if webapp
      apps.setDefaultApp webapp
    apps.bindToHttpServer @httpServer

  # localAddr:  [addr:]port, the local address to listen at, i.e. localhost:8888, 8888, 0.0.0.0:8888
  start: (localAddr, cb)->
    { host, port } = parseAddress(localAddr)

    @httpServer.listen port, host, (err)=>
      if cb then cb(err)

      @wsServer.on 'request', (request)=>

        wsConn = request.accept('tunnel-protocol', request.origin);
        httpRequest = request.httpRequest
        tunnelPort = url.parse(httpRequest.url, true).query.port

        tcpServer = net.createServer();
        tcpServer.listen(tunnelPort)

        tcpServer.on("connection", (tcpConn) =>
          # pipe incoming tcp connection to the websocket
          wsStream = new WsIdStream(wsConn, @counter++)
          bindStream(tcpConn, wsStream)
        )

        wsConn.on 'close', () =>
          log "websocket closed"
          tcpServer.close(() => log "tcpServer closed")

        log "opened a new tunnel entrance at #{tunnelPort}"