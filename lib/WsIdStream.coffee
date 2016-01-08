stream = require "stream"

decoder = require "./buffer-decoder"

# Stream wrapper for http://github.com/Worlize/WebSocket-Node.git version 1.0.8
module.exports = class WsIdStream extends stream.Duplex

  onMessage: (message) =>
    { identifier, chunk } = decoder.decode(message.binaryData)
    # drop the segment if the identifiers don't match
    if @identifier == identifier and @_open
      @push chunk

  onClose: () =>
    @_open = false
    @emit 'close'

  onError: () =>
    @emit 'error', err

  constructor: (@ws, @identifier)->
    super()
    @_sig = "ws"
    @_open = true
    @ws.on 'message', @onMessage
    @ws.on 'close', @onClose
    @ws.on "error", @onError

  end : ()->
    super()
    @ws.removeListener 'message', @onMessage
    @ws.removeListener 'close', @onClose
    @ws.removeListener 'error', @onError

  # node stream overrides
  # @push is called when there is data, _read does nothing
  _read : ()->
  # if callback is not called, then stream write will be blocked
  _write: (chunk, encoding, callback)->
    chunk = decoder.encode(chunk, @identifier)
    if @_open then @ws.sendBytes(chunk, callback)

