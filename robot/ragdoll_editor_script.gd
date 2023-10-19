@tool
extends EditorScript

func _run():
	var this = get_scene()
	for n in this.get_children():
		if n is MeshInstance3D:
			if n.get_child_count() > 0:
				var rb = RigidBody3D.new()
				this.add_child(rb, true)
				rb.set_owner(this)
				rb.position = -n.position
				var coll = n.get_children()[0].get_children()[0]
				coll.reparent(rb)
				coll.position = n.position
				coll.set_owner(this)
				n.reparent(rb, false)
				n.set_owner(this)
				n.visible = true
				rb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			else:
				n.create_convex_collision()
		if n is RigidBody3D:
			pass
