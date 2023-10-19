class_name MapBuilder extends GridMap

var objects:Array[FunctionalObject] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func build_tiles(data:Dictionary):
	pass



# an enum that has all the possible errors when checking validity
enum errorType {
	valid,
	noTilesArray,
	tileArrayEmpty,
	tileRowNotArray,
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
	"the key \"%s\" in \"tile_defs\" is not a string",
	"\"tile_defs\" does not contain \"%s\" as a key",
	"tile \"%s\" contains a non-number value (%s)",
	"array tile \"%s\" doesn't contain enough elements",
	"dict tile \"%s\" doesn't contain a valid \"type\" field",
	"tile \"%s\" is not a valid tile"
]
# a function to validate the map json
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
		if res:
			return res
	# there has to be a tiles array
	if not (data.has("tiles") and data["tiles"] is Array):
		return RAW_ERRORS[errorType.noTilesArray]
	# the tiles array can't be empty
	if not (data["tiles"].is_empty()):
		return RAW_ERRORS[errorType.tileArrayEmpty]
	for line in data["tiles"]:
		# we check each line is an array of valid tiles
		if not line is Array:
			return RAW_ERRORS[errorType.tileRowNotArray] % line
		for possibleTile in line:
			# or an array of arrays of valid tiles
			res = is_tile_valid(possibleTile, data["tile_defs"] if hasSubs else {})
			if res: 
				if not possibleTile is Array:
					return RAW_ERRORS[errorType.tileRowNotArray] % possibleTile
				for tile in possibleTile: 
					res = is_tile_valid(tile, data["tile_defs"] if hasSubs else {})
					if res:
						return res
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
	elif not (tile is int or tile is float):
		# a tile that isn't an array, dict or string has to be a number
		return RAW_ERRORS[errorType.tileInvalidType] % tile
	# a tile has to be a valid array, valid dict, or simple number
	return RAW_ERRORS[errorType.valid]
