###
Minecraft Anvil File reader and writer based on https://github.com/thejonwithnoh/mca-js
###

zlib = require 'zlib'

layout =
	sectorOffsetSize: 3
	sectorCountSize: 1
	timestampSize: 4
	dataSizeSize: 4
	compressionTypeSize: 1
	dimensionSizePower: 5
	dimensionCount: 2
	sectorSizePower: 12

layout.sectorDetailsSize = layout.sectorOffsetSize + layout.sectorCountSize
layout.dataHeaderSize = layout.dataSizeSize + layout.compressionTypeSize
layout.dimensionSize = 1 << layout.dimensionSizePower
layout.dimensionSizeMask = layout.dimensionSize - 1
layout.indexCount = layout.dimensionSize * layout.dimensionCount
layout.headerSize = layout.sectorDetailsSize * layout.indexCount
layout.sectorSize = 1 << layout.sectorSizePower

getIndex = (dimensions) ->
	index = 0
	for dimension in [0...layout.dimensionCount]
		index |= (dimensions[dimension] & layout.dimensionSizeMask) << dimension * layout.dimensionSizePower
	return index

getSectorOffsetOffset = (dimensions) ->
	result = getIndex(dimensions) * layout.sectorDetailsSize
	return result

getSectorCountOffset = (dimensions) ->
	return getSectorOffsetOffset(dimensions) + layout.sectorOffsetSize

getTimestampOffset = (dimensions) ->
	return getIndex(dimensions) * layout.timestampSize + layout.headerSize

compressionTypes =
	uncompressed:
		value: 0
		compress: (data, callback) -> callback data
		compressSync: (data) -> data
		decompress: (data, callback) -> callback data
		decompressSync: (data) -> data
	gzip:
		value: 1
		compress: zlib.gzip
		compressSync: zlib.gzipSync
		decompress: zlib.gunzip
		decompressSync: zlib.gunzipSync
	zlib:
		value: 2
		compress: zlib.deflate
		compressSync: zlib.deflateSync
		decompress: zlib.inflate
		decompressSync: zlib.inflateSync

for compressionTypeName in Object.keys(compressionTypes)
	compression = compressionTypes[compressionTypeName]
	compression.name = compressionTypeName
	compressionTypes[compression.value] = compression

getSectorOffset = (buffer, dimensions) ->
	result = buffer.readUIntBE getSectorOffsetOffset(dimensions), layout.sectorOffsetSize
	return result

getDataOffset = (buffer, dimensions) ->
	result = getSectorOffset(buffer, dimensions) << layout.sectorSizePower
	return result

getSectorCount = (buffer, dimensions) ->
	return buffer.readUIntBE getSectorCountOffset(dimensions), layout.sectorCountSize

getTimestamp = (buffer, dimensions) ->
	return buffer.readUIntBE getTimestampOffset(dimensions), layout.timestampSize

getDataSize = (buffer, dimensions) ->
	result = buffer.readUIntBE(getDataOffset(buffer, dimensions), layout.dataSizeSize) - layout.compressionTypeSize
	return result

getCompressionType = (buffer, dimensions) ->
	compressionType = buffer.readUIntBE(getDataOffset(buffer, dimensions) + layout.dataSizeSize, layout.compressionTypeSize)
	return compressionTypes[compressionType]

getData = (buffer, dimensions) ->
	dataStart = getDataOffset buffer, dimensions
	if dataStart
		payloadStart = dataStart + layout.dataHeaderSize
		payloadEnd = getDataSize(buffer, dimensions) + payloadStart
		payload = buffer.slice payloadStart, payloadEnd
		return getCompressionType(buffer, dimensions).decompressSync payload
	else
		return null

updateDataSize = (buffer, dimensions, newDataSize) ->
	buffer.writeUIntBE(newDataSize + layout.compressionTypeSize, getDataOffset(buffer, dimensions), layout.dataSizeSize)
	return

updateSectorOffset = (buffer, dimensions, newSectorOffset) ->
	buffer.writeUIntBE newSectorOffset, getSectorOffsetOffset(dimensions), layout.sectorOffsetSize
	return

updateData = (buffer, dimensions, newPayload) ->
	dataStart = getDataOffset buffer, dimensions
	if dataStart
		payloadStart = dataStart + layout.dataHeaderSize
		payloadEnd = getDataSize(buffer, dimensions) + payloadStart
		compressed = getCompressionType(buffer, dimensions).compressSync newPayload
		
		updateDataSize buffer, dimensions, compressed.length
		
		for i in [0...compressed.length]
			buffer.writeUInt8 compressed[i], payloadStart + i
		return buffer
	else
		return null

module.exports = {
	getData
	updateData
}
