# encode the buffer with an identifier
module.exports.encode = (buffer, id) =>
  identifier = new Buffer(4)
  identifier.writeUInt32BE(id, 0)
  return Buffer.concat([identifier, buffer], buffer.length + 4)

# decode an buffer encoded with the `encode` method and return
# the original chunk and the identifier
module.exports.decode = (buffer) => {
  identifier: buffer.slice(0, 4).readUInt32BE(0),
  chunk: buffer.slice(4, buffer.length)
}
