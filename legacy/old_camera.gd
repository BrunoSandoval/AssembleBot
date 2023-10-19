extends Camera3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var centerPos = Vector3(2, 10, 1.5)
var centerRot = Vector3(-90, 0, 0)

var chosenCam = 0

func _ready():
	pass


#func _process(delta):
#	pass

func updatePos(pos,rot):
	match chosenCam:
		1:
			position = pos+Vector3(0,10,0)
			rotation_degrees = centerRot
		2:
			position = pos+Vector3(0,10,0)
			rotation_degrees = centerRot+rot
		3:
			position = pos+Vector3(-0.06*sin(deg_to_rad(rot.y)),0.85,-0.06*cos(deg_to_rad(rot.y)))
			rotation_degrees = rot
		4:
			position = pos+Vector3(2*sin(deg_to_rad(rot.y)),1.25,2*cos(deg_to_rad(rot.y)))
			rotation_degrees = rot
		5:
			position = pos+Vector3(1.5*sin(deg_to_rad(rot.y)),1.25,1.5*cos(deg_to_rad(rot.y)))+Vector3(0.5*cos(deg_to_rad(rot.y)),0,-0.5*sin(deg_to_rad(rot.y)))
			rotation_degrees = rot
		6:
			position = pos+Vector3(1.5*sin(deg_to_rad(rot.y)),1.25,1.5*cos(deg_to_rad(rot.y)))+Vector3(-0.5*cos(deg_to_rad(rot.y)),0,0.5*sin(deg_to_rad(rot.y)))
			rotation_degrees = rot
		_:
			position = centerPos
			rotation_degrees = centerRot


func _on_FixedCam_pressed():
	chosenCam = 0
func _on_TopDown_pressed():
	chosenCam = 1
func _on_TopDownRotate_pressed():
	chosenCam = 2
func _on_FirstPerson_pressed():
	chosenCam = 3
func _on_ThirdPerson_pressed():
	chosenCam = 4
func _on_ShoulderSurfR_pressed():
	chosenCam = 5
func _on_ShoulderSurfL_pressed():
	chosenCam = 6

