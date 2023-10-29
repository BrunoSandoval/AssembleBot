@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var root = get_scene()
	var basics:Array[Node] = root.get_children()
	var tmp:MeshInstance3D
	for shape in basics: if shape is MeshInstance3D:
		var texturesDir = DirAccess.open("res://game_map/tiles/basic/%s"% shape.name)
		for filePath in texturesDir.get_files():
			if not filePath.ends_with(".png") or filePath.begins_with("00"):
				continue
			tmp = shape.duplicate(0)
			tmp.mesh = tmp.mesh.duplicate()
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = load(texturesDir.get_current_dir()+"/"+filePath)
			tmp.mesh.surface_set_material(0, mat)
			
			root.add_child(tmp, true)
			tmp.set_owner(root)
			for coll in tmp.get_children():
				coll.set_owner(root)
				for hitbox in coll.get_children():
					hitbox.set_owner(root)
