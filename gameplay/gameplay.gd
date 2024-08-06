extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if (GameMaster.mapData != null) or OS.has_feature("editor"):
		await $GameMap.build_map(GameMaster.mapData)
	$Camera3D.updatePos($Robot.position, $Robot.rotation_degrees)

func _on_gui_request_lines_check(lines:Array[String], start_line:int):
	pass
	#for i in range(lines.size()):
		
		#var res:ParserData.LineCheckResult = parser._check_line(lines[i])
		#if true:
			#pass
#			if known_errors.has(start_line+i):
#				known_errors.erase(start_line+i)
#				$GUI.disappear_parse_error(start_line+i)
#		else:
#			if lines.size() > 1 or lines[i].ends_with(" "):
#				known_errors[start_line+i] = res
	#$GUI.merge_tracked_errors(parser.errors)
