log = require "lawg"
net = require "net"
url = require "url"
WebsocketClient = require("websocket").client

decoder = require "./buffer-decoder"

# silence the log by default
verboseLog = log
log = () =>

module.exports = class wst_client extends require("events").EventEmitter

 verbose : ()->
    @on "tunnel", (ws)=> log "Websocket tunnel established"
    @on "connectFailed", (error)=> log("WS connect error", error)
    log = verboseLog

  # example:  start("wss://ws.domain.com:454", 9000, "dst.domain.com:22")
  #
  # Request to the server at `wsHostUrl` to listen at port `tunnelPort`. The
  # incoming requests are tunneled by the client to `targetAddress` in the
  # client network
  start: (tunnelPort, wsHostUrl, targetAddress, optionalHeaders, cb)->
    @connections = {}
    [ @targetHost, @targetPort ] = targetAddress.split(":")
    if typeof optionalHeaders == "function"
      cb = optionalHeaders
      optionalHeaders = { }

    @authorize(wsHostUrl, optionalHeaders)

    log "Connecting to WS server at #{wsHostUrl}"
    wsClient = new WebsocketClient()
    wsHostUrl = "#{wsHostUrl}/?port=#{tunnelPort}"
    log wsHostUrl
    wsClient.connect(wsHostUrl, "tunnel-protocol", undefined, optionalHeaders)

    wsClient.on "connectFailed", (error) => @emit "connectFailed", error

    wsClient.once "connect", (wsConn) =>
      @emit "tunnel", wsConn
      @wsConn = wsConn
      wsConn.on "message", (msg) => @handleIncomingRequest(msg)

    wsClient.on "close", () => log "WS closed"

  # open a new connection for each new incoming identifier. Each identifier
  # corresponds to an open TCP connection on the server
  openConnection: (identifier, onOpen) =>
    tcpConn = @connections[identifier]

    if !tcpConn
      tcpConn = net.connect {host: @targetHost, port: @targetPort}
      @connections[identifier] = tcpConn

      tcpConn.once "connect", () =>
        log "TCP connection established"
        tcpConn.on "drain", (chunk) => log "TCP connection drain"
        tcpConn.on "end", (chunk) => log "TCP connection end"
        tcpConn.on "error", (chunk) => log "TCP connection error"
        tcpConn.on "close", (chunk) => @connections[identifier] = undefined
        tcpConn.on "data", (chunk) =>
          log "TCP connection data"
          chunk = decoder.encode(chunk, identifier)
          @wsConn.sendBytes(chunk)

        onOpen(tcpConn)

    else
      onOpen(tcpConn)


  handleIncomingRequest: (message) =>
    log "WS message received"
    { chunk, identifier } = decoder.decode(message.binaryData)
    @openConnection identifier, (tcpConn) => tcpConn.write(chunk)

  authorize: (urlString, headers) =>
    auth = url.parse(urlString).auth
    if auth
      headers.Authorization = "Basic " +(new Buffer(auth)).toString("base64")
