extends CharacterBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal robotFinished

var targetPos = Vector3(0,0,0);
var targetA = 0;
var speed = 1;

var executing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$RobotModel/AnimationPlayer.play("ForceReset")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _physics_process(delta):
	var rayData = PhysicsRayQueryParameters3D.create(position+Vector3(0,0.1,0), position+Vector3(0,-0.9,0), 0b1110, [])
	var ray = get_world_3d().direct_space_state.intersect_ray(rayData)
	if ray:
		rotation_degrees.x = ray.normal.x
		rotation_degrees.z = ray.normal.z
	
	if targetPos.x != position.x:
		position.x += sign(targetPos.x-position.x)*delta*speed
		if abs(targetPos.x-position.x) <= 0.01:
			position.x = targetPos.x
		return
		
	if targetPos.z != position.z:
		position.z += sign(targetPos.z-position.z)*delta*speed
		if abs(targetPos.z-position.z) <= 0.01:
			position.z = targetPos.z
		return
	
	if targetA != rotation_degrees.y:
		rotation_degrees.y += sign(targetA-rotation_degrees.y)*delta*90*speed
		if abs(targetA-rotation_degrees.y) <= 1:
			rotation_degrees.y = targetA
		return
		
	if $RobotModel/AnimationPlayer.is_playing():
		return
	
	if executing:
		self.emit_signal("robotFinished")
		executing = false

func do(op):
	match op:
		1:
			targetPos.x -= round(sin(deg_to_rad(rotation_degrees.y)))
			targetPos.z -= round(cos(deg_to_rad(rotation_degrees.y)))
			for b in $Eyes.get_overlapping_bodies():
				if b.collision_mask & 1:
					targetPos.x = position.x
					targetPos.z = position.z
					$RobotModel/AnimationPlayer.play("LookAndDeny")
		2:
			targetPos.x += round(sin(deg_to_rad(rotation_degrees.y)))
			targetPos.z += round(cos(deg_to_rad(rotation_degrees.y)))
			for b in $EyesBack.get_overlapping_bodies():
				if b.collision_mask & 1:
					targetPos.x = position.x
					targetPos.z = position.z
					$RobotModel/AnimationPlayer.play("LookAndDeny")
		3:
			targetA -= 90
		4:
			targetA += 90
		5:
			targetA += 180
		6:
			$RobotModel/AnimationPlayer.play("IdleWave")
		_:
			return
	if targetA > 360:
		targetA -= 360
		rotation_degrees.y -= 360
	if targetA < 0:
		targetA += 360
		rotation_degrees.y += 360
	executing = true

func lookingAt():
	for b in $Eyes.get_overlapping_bodies():
		if b.collision_mask & 1:
			return 1
		elif b.collision_mask & 2:
			pass
	return 0


func set_speed(value):
	self.speed = value
