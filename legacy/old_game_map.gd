extends GridMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var built = false

var camPos = Vector3(0,10,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func loadFromJSON(mapData):
	if mapData.has("tiles"):
		if mapData["tiles"].has("layers"):
			self.clear()
			if mapData.has("tile_offsets"):
				for layerN in range(mapData["tiles"]["layers"].size()):
					self.buildGrid(mapData["tiles"]["layers"][mapData["tiles"]["layers"].size()-layerN-1],
						mapData["tile_offsets"]["x"] if mapData["tile_offsets"].has("x") else 0,
						mapData["tile_offsets"]["y"] if mapData["tile_offsets"].has("y") else 0,
						mapData["tile_offsets"]["height"]+layerN if mapData["tile_offsets"].has("height") else layerN)
			else:
				for layerN in range(mapData["tiles"]["layers"].size()):
					self.buildGrid(mapData["tiles"]["layers"][mapData["tiles"]["layers"].size()-layerN-1],0,0,layerN)
			self.built = true
		elif mapData["tiles"] is Array:
			self.clear()
			if mapData.has("tile_offsets"):
				self.buildGrid(mapData["tiles"],
					mapData["tile_offsets"]["x"] if mapData["tile_offsets"].has("x") else 0,
					mapData["tile_offsets"]["y"] if mapData["tile_offsets"].has("y") else 0,
					mapData["tile_offsets"]["height"] if mapData["tile_offsets"].has("height") else 0)
			else:
				self.buildGrid(mapData["tiles"])
			self.built = true
	if mapData.has("fixed_camera_pos"):
		setCamPos(mapData["fixed_camera_pos"])

func setCamPos(fixedPos:Dictionary):
	if fixedPos.has("x"):
		camPos.x = fixedPos["x"]
	if fixedPos.has("y"):
		camPos.z = fixedPos["y"]


func buildGrid(tiles:Array, offsetx:int = 0, offsety:int = 0, height:int=0):
	var x = offsetx
	var y = offsety
	for line in tiles:
		if line is Array:
			for cell in line:
				if cell is int or cell is float:
					self.set_cell_item(Vector3(x, height, y), int(cell))
				elif cell is Dictionary:
					if cell.has("type") and (cell["type"] is int or cell["type"] is float):
						if cell.has("rot") and (cell["rot"] is int or cell["rot"] is float):
							self.set_cell_item(Vector3(x, height, y), int(cell["type"]), get_orthogonal_index_from_basis(Basis(Vector3.UP, PI*0.5*cell["rot"])))
						else:
							self.set_cell_item(Vector3(x, height, y), int(cell["type"]))
				elif cell is Array:
					if cell.size() > 0:
						if cell.size() > 1:
							self.set_cell_item(Vector3(x, height, y), int(cell[0]), get_orthogonal_index_from_basis(Basis(Vector3.UP, PI*0.5*cell[1])))
						else:
							self.set_cell_item(Vector3(x, height, y), int(cell[0]))
				x += 1
		elif line is int or line is float:
			self.set_cell_item(Vector3(x, height, y), int(line))
		y += 1
		x = offsetx
