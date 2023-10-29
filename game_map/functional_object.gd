class_name FunctionalObject extends PhysicsBody3D

var startPos:Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	startPos = position

# called when the level is started to play
# rng values to be generated here
func prepare():
	pass

# called when the level is reset, to bring the object to its base state
func reset():
	position = startPos
