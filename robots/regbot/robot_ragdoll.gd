extends Node3D

@export_range(0, 16)
var explosionForce:float = 0
@export
var explosionVec:Vector3i = Vector3i()
@export_range(0, 1)
var explosionVariance:float = 1

func _ready():
	for n in get_children():
		if n is RigidBody3D:
			if explosionVec:
				n.apply_central_impulse(explosionForce*explosionVec/explosionVec.length())
			else:
				n.apply_central_impulse(n.position.normalized()*explosionForce+Vector3(
					randfn(0, explosionVariance),
					randfn(0, explosionVariance),
					randfn(0, explosionVariance)
				).normalized()*explosionVariance)
