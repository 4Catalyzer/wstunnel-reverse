# parse an address into host and port.
# If address is only port, host will be localhost
module.exports.parseAddress = (address)->
  if typeof address == 'number' then port = address
  else
    [host, port] = address.split ':'
    if /^\d+$/.test(host)
      port = host
      host = null
    port = parseInt(port)

  host ?= '127.0.0.1'
  { host, port }
