fs = require 'fs'
path = require 'path'
async = require 'async'
mca = require './mca'
nbt = require './nbt'
zlib = require 'zlib'

if process.argv.length < 4
	console.log '''
	  Usage: coffee index.coffee <frompath> <topath>
	  
	  frompath: Path to savegame to read fortress data from.
	  topath: Path to savegame to write fortress data to.
	'''
	return process.exit(0)

fromDirectory = path.join process.argv[2], 'DIM-1/region'
toDirectory = path.join process.argv[3], 'DIM-1/region'

fromFiles = fs.readdirSync(fromDirectory).filter (file) -> file.endsWith '.mca'
toFiles = fs.readdirSync(toDirectory).filter (file) -> file.endsWith '.mca'

chunksPerFile = 32

async.eachSeries fromFiles, (fromFile, nextFromFile) ->
	console.log fromFile
	if toFiles.includes fromFile
		fromContent = fs.readFileSync path.join fromDirectory, fromFile
		toContent = fs.readFileSync path.join toDirectory, fromFile
		async.eachSeries [0...chunksPerFile], (chunkX, nextChunkX) ->
			async.eachSeries [0...chunksPerFile], (chunkY, nextChunkY) ->
				fromDataBin = mca.getData fromContent, [chunkX, chunkY]
				toDataBin = mca.getData toContent, [chunkX, chunkY]
				if fromDataBin? and toDataBin?
					nbt.parse fromDataBin, (error, fromNbtdata) ->
						nbt.parse toDataBin, (error, toNbtdata) ->
							if fromNbtdata.value.Level.value.Structures.value.References.value? and fromNbtdata.value.Level.value.Structures.value.References.value.Fortress? and fromNbtdata.value.Level.value.Structures.value.References.value.Fortress.value?
								if not toNbtdata.value.Level.value.Structures?
									toNbtdata.value.Level.value.Structures =
										type: 'compound'
								if not toNbtdata.value.Level.value.Structures.value?
									toNbtdata.value.Level.value.Structures.value = {}
								if not toNbtdata.value.Level.value.Structures.value.References?
									toNbtdata.value.Level.value.Structures.value.References =
										type: 'compound'
								if not toNbtdata.value.Level.value.Structures.value.References.value?
									toNbtdata.value.Level.value.Structures.value.References.value = {}
								if not toNbtdata.value.Level.value.Structures.value.References.value.Fortress?
									toNbtdata.value.Level.value.Structures.value.References.value.Fortress =
										type: 'longArray'
								toNbtdata.value.Level.value.Structures.value.References.value.Fortress.value = fromNbtdata.value.Level.value.Structures.value.References.value.Fortress.value
							if fromNbtdata.value.Level.value.Structures.value.Starts.value? and fromNbtdata.value.Level.value.Structures.value.Starts.value.Fortress? and fromNbtdata.value.Level.value.Structures.value.Starts.value.Fortress.value?
								if not toNbtdata.value.Level.value.Structures?
									toNbtdata.value.Level.value.Structures =
										type: 'compound'
								if not toNbtdata.value.Level.value.Structures.value?
									toNbtdata.value.Level.value.Structures.value = {}
								if not toNbtdata.value.Level.value.Structures.value.Starts?
									toNbtdata.value.Level.value.Structures.value.Starts =
										type: 'compound'
								if not toNbtdata.value.Level.value.Structures.value.Starts.value?
									toNbtdata.value.Level.value.Structures.value.Starts.value = {}
								if not toNbtdata.value.Level.value.Structures.value.Starts.value.Fortress?
									toNbtdata.value.Level.value.Structures.value.Starts.value.Fortress =
										type: 'compound'
								toNbtdata.value.Level.value.Structures.value.Starts.value.Fortress.value = fromNbtdata.value.Level.value.Structures.value.Starts.value.Fortress.value
							mca.updateData toContent, [chunkX, chunkY], nbt.writeUncompressed toNbtdata
							return nextChunkY()
						return
					return
				else
					return nextChunkY()
			, (error) ->
				return nextChunkX()
		, (error) ->
			fs.writeFileSync path.join(toDirectory, fromFile), toContent
			return nextFromFile()
	else
		return nextFromFile()
, (error) ->
	console.log 'Done!'
