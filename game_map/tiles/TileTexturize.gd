@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var root = get_scene()
	var basics:Array[Node] = root.get_children()
	var tmp:MeshInstance3D
	var tmpN:Node
	for shape in basics: if shape is MeshInstance3D:
		tmp = shape.duplicate()
		root.add_child(tmp, true)
		tmp.set_owner(root)
		for coll in tmp.get_children():
			coll.set_owner(root)
			for hitbox in coll.get_children():
				hitbox.set_owner(root)
		for file in DirAccess.open("res://game_map/tiles/%s" % shape.namesync).get_files():
			pass
