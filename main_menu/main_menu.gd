extends Node3D

# the parsed data of the map json
var mapData = JSON.parse_string( 
	FileAccess.open( 
		"res://game_map/playground.json", 
		FileAccess.READ
	).get_as_text()
)
# a list of all available idle animations
var idleAnimList = []
# this is just for a mildly amusing effect
var robotRagdoll:Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# build the idle animation names array
	for anim in $RobotModel/AnimationPlayer.get_animation_list():
		# animations have to start with the word idle to be registered
		if anim.to_lower().begins_with("idle"):
			idleAnimList.append(anim)
	# make the robot refresh the idle timer when an animation ends
	$RobotModel/AnimationPlayer.connect("animation_finished", Callable(self, "reset_idle_timer"))
	# put the robot into the rest pose and kickstart the idle timer
	$RobotModel/AnimationPlayer.play("ForceReset")

# a function connected to the idle timer timeout signal, to play the idle
func play_random_idle():
	$RobotModel/AnimationPlayer.play(idleAnimList[randi_range(0, len(idleAnimList)-1)])
# a function connected to the robot anim player finishing, to reset the timer
func reset_idle_timer(_anim_name = ""):
	$IdleTimer.start(randi_range(6, 30))

# when the top block is clicked, start the game
func _on_start_block_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton && mapData != null:
		if event.pressed == false and event.button_index == 1:
			GameMaster.load_map(mapData)
# when the middle block is clicked, open the map picking screen
func _on_select_map_block_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed == false and event.button_index == 1:
			$PickMapScreen.show_picker()
# take a guess what happens when the exit block is clicked
func _on_exit_block_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed == false and event.button_index == 1:
			if OS.get_name() == "Web":
				JavaScriptBridge.eval("window.location = \"https://brunosandoval.github.io\"")
			else:
				get_tree().quit(0)

# when the mouse enters any block, highlight and play a sound
func _on_block_mouse_entered(block:String, checkMap:bool = false):
	if $PickMapScreen.is_visible() || $ParseErrorMessage.visible || (checkMap and mapData == null):
		return
	get_node(block+"/HighlightBlock").visible = true
	$Bloop.play()

# unhighlight when mouse exits the block
func _on_block_mouse_exited(block:String):
	get_node(block+"/HighlightBlock").visible = false


# validate chosen file, and show error messages if invalid
func _on_pick_map_screen_closed(JSONPath:String):
	if OS.get_name() == "Web" and not JSONPath.begins_with("res://"):
		$HTTPRequest.request(JSONPath)
		return
	# try to open the file
	var levelFile = FileAccess.open(JSONPath, FileAccess.READ)
	# when it can't be opened, show the error message and return
	if levelFile == null:
		# this also disables the start button (and explodes the robot)
		show_parse_error_message(
			"There was an error when opening %s:\n%s"
			%[JSONPath, FileAccess.get_open_error()]
		)
		return
	validateJSONString(JSONPath, levelFile.get_as_text())

# validates the read string, path is just for the error message
func validateJSONString(path:String, data:String):
	# try and parse the json in the file
	var parser = JSON.new()
	var parseResult = parser.parse(data)
	# when the json isn't valid, show the error message and return
	if parseResult:
		show_parse_error_message(
			"There was an error when parsing %s:\nError at line %s:\n%s"
			%[path, parser.get_error_line(), parser.get_error_message()]
		)
		return
	var mapResponse = MapBuilder.is_valid(parser.data as Dictionary)
	if mapResponse:
		show_parse_error_message(mapResponse)
		return
	# we undo the error message side effects
	$StartBlock/BaseBlock.get_active_material(0).albedo_color = Color.WHITE
	mapData = parser.data

# we show the error message, and disable the start button
func show_parse_error_message(msg:String):
	# show the actual error message
	$ParseErrorMessage.dialog_text = msg
	$ParseErrorMessage.popup()
	# disable the start button visually, and functionally respectively
	$StartBlock/BaseBlock.get_active_material(0).albedo_color = Color("#696969")
	mapData = null

# connected to the error window, to show the map picker when it closes
func _on_parse_error_message_confirmed():
	$PickMapScreen.show_picker()

# connected to the pick map screen, for when an error happens
func _on_pick_map_screen_request_error(errorCode):
	show_parse_error_message(errorCode)

# this function connects to the HTTPRequest node
func _on_http_request_request_completed(result, response_code, _headers, body):
	if result:
		# show the error message when we couldn't fetch the level
		show_parse_error_message(
			"Could not fetch the level data:\n%s"
			% response_code
		)
	# we parse the json that was sent over
	validateJSONString("remote level", body.get_string_from_utf8())
