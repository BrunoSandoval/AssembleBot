class_name MapBuilder extends GridMap

const DEFAULT_TILE_TEXTURES:String = "res://game_map/tiles/basic/"

var objects:Array[FunctionalObject] = []

var tileSubs:Dictionary = {}

# this function prepares the entire map
func build_map(data:Dictionary):
	# we update the tile substitutions dictionary
	if data.has("tile_defs"):
		tileSubs = data["tile_defs"]
	# we make the offsets vector if offset_map exists
	# the default value being one block away from the origin
	var offsets = Vector3(
		-data["offset_map"][0],
		data["offset_map"][1] if len(data["offset_map"]) > 2 else 0,
		-data["offset_map"][2 if len(data["offset_map"]) > 2 else 1]
	) if data.has("offset_map") and len(data["offset_map"]) > 1 else Vector3(-1,0,-1)
	# finding the depth, to handle the tiles array appropriately
	var depth = MapBuilder.find_depth(data["tiles"])
	var space:Array[Array] = []
	if depth == 2:
		space.append(data["tiles"])
	else:
		space.append_array(data["tiles"])
	# iterate through the planes, rows and tiles and place them
	# this formatting feels bad
	# but that much indent feels worse
	for y in range(len(space)):
		for z in range(len(space[y])):
			for x in range(len(space[y][z])):
				self.place_tile(Vector3(x,len(space)-y-1,z)+offsets, space[y][z][x])

# a function to place each tile
func place_tile(pos:Vector3, tile):
	if tile == null: return
	var type:int
	var rot:int = 0
	var texture:int = 0
	match typeof(tile):
		TYPE_INT, TYPE_FLOAT:
			# number tiles are just the type
			type = tile
		TYPE_STRING:
			# for string tiles we place their substitution
			place_tile(pos, tileSubs[tile])
		TYPE_ARRAY:
			# array tiles depend on their size, but the order is type rotation texture
			type = tile[0]
			rot = tile[1] if len(tile) > 1 else 0
			texture = tile[2] if len(tile) > 2 else 0
		TYPE_DICTIONARY:
			# dict tiles are the most self explainatory
			type = tile["type"]
			rot = tile["rot"] if tile.has("rot") else 0
			texture = tile["texture"] if tile.has("texture") else 0
	if texture and texture > 0:
		# yes, meshlibs have to have this metadata, an array of ints
		# each value corresponds to a type of tile, and the value is the start of the
		# retextured/remodeled variants of that tile type
		var startIndices = mesh_library.get_meta("TextureStartIndices", [])
		if len(startIndices) > type:
			type = startIndices[type]+texture-1
			print(type)
	self.set_cell_item(
		pos, type,  # why godot 4, why
		get_orthogonal_index_from_basis(Basis.from_euler(Vector3(0,rot*PI/2,0)))
	)

# a function to find how many dimensions a tile array has
# the only requirement is to have one (1) non-array
# it's a simple breadth first search
static func find_depth(arr:Array) -> int:
	var depth = 0
	var search = []
	var queue = []
	search.append(arr)
	while search:
		for a in search:
			if a is Array:
				queue.append_array(a)
			else:
				return depth
		depth += 1
		search.clear()
		search.append_array(queue)
		queue.clear()
	return depth

# an enum that has all the possible errors when checking validity
enum errorType {
	valid,
	noTilesArray,
	tileArrayEmpty,
	tileRowNotArray,
	tileArrayWrongDepth,
	subNameNotString,
	subTileNotDefined,
	collectionTileInvalidType,
	arrayTileTooSmall,
	dictTileLacksType,
	tileInvalidType
}
# the error messages, ready for formatting and display
const RAW_ERRORS:Array[String] = [
	"",
	"\"tiles\" array could not be found",
	"\"tiles\" array is empty",
	"\"%s\" in the \"tiles\" array is not an array",
	"\"tiles\" has to be 2 or 3 dimensional array of tiles",
	"the key \"%s\" in \"tile_defs\" is not a string",
	"\"tile_defs\" does not contain \"%s\" as a key",
	"tile \"%s\" contains a non-number value (%s)",
	"array tile \"%s\" doesn't contain enough elements",
	"dict tile \"%s\" doesn't contain a valid \"type\" field",
	"tile \"%s\" is not a valid tile"
]
# a function to validate the map json
# this doesn't have to be That optimized
# it runs once when loading a map
static func is_valid(data:Dictionary) -> String:
	var res:String
	# check if there are defined substitutions
	var hasSubs = data.has("tile_defs") \
				and data["tile_defs"] is Dictionary \
				and not data["tile_defs"].is_empty()
	# check every substitution is valid
	if hasSubs: for key in data["tile_defs"].keys():
		if not key is String:
			return RAW_ERRORS[errorType.subNameNotString] % key
		res = is_tile_valid(data["tile_defs"][key])
		if res: return res
	# there has to be a tiles array
	if not (data.has("tiles") and data["tiles"] is Array):
		return RAW_ERRORS[errorType.noTilesArray]
	# the tiles array can't be empty
	if data["tiles"].is_empty():
		return RAW_ERRORS[errorType.tileArrayEmpty]
	# we check that it's an array of arrays, or an array of arrays of tiles
	var depth = find_depth(data["tiles"])
	# this guarantees the arrayhood of certain elements
	# considering that tiles can be arrays, it's a bit weird
	if 2 > depth or depth > 4:
		return RAW_ERRORS[errorType.tileArrayWrongDepth]
	for layer in data["tiles"]: #2 means row, 3&4 means plane
		var search:Array[Array] = []
		if depth == 2:
			# when depth is two, we have an array of arrays of tiles
			search.append(layer)
		else:
			# when depth is 3 or 4, we assume it's a 3d array of tiles
			search.append_array(layer)
		# we check all the tiles
		for line in search: for tile in line:
			res = is_tile_valid(tile, data["tile_defs"].keys if hasSubs else [])
			if res: return res
	return RAW_ERRORS[errorType.valid]

# a function to validate tiles
static func is_tile_valid(tile:Variant, subKeys:Array = []) -> String:
	if tile is Array:
		# the array tile has to have at least one element
		if tile.size() <= 0:
			return RAW_ERRORS[errorType.arrayTileTooSmall] % tile
		for v in tile:
			# all of the elements have to be numbers
			if not (v is int or v is float):
				return RAW_ERRORS[errorType.collectionTileInvalidType] % [tile, v]
	elif tile is Dictionary:
		# the dict tile has to have a type field
		if not tile.has("type"):
			return RAW_ERRORS[errorType.dictTileLacksType] % tile
		# the type field has to have a number as a value
		if not (tile["type"] is float or tile["type"] is int):
			return RAW_ERRORS[errorType.collectionTileInvalidType] % [tile, tile["type"]]
	elif tile is String and subKeys:
		# optionally, it has to be a defined substitution
		if not subKeys.has(tile):
			return RAW_ERRORS[errorType.subTileNotDefined] % tile
	elif not (tile is int or tile is float or tile == null):
		# a tile that isn't an array, dict or string has to be a number
		# or null, indicating empty cell
		return RAW_ERRORS[errorType.tileInvalidType] % tile
	# a tile has to be a valid array, valid dict, or simple number
	return RAW_ERRORS[errorType.valid]
