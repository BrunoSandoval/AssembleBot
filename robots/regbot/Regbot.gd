class_name RobotBase
extends CharacterBody3D

var processor:Processor
@onready var start_transform:Transform3D = self.transform
@onready var tween:Tween = null

var fall_damage_threshold:float = 0.4
var ragdoll:bool = false
var tween_duration:float = 0.6
var acting:bool:
	get:
		return $AnimationPlayer.is_playing() or (self.tween != null and self.tween.is_running())

func _ready():
	self.processor = AMDProcessor.new()
	$AnimationPlayer.play(&"ForceReset")

func _physics_process(delta):
	if $FeetRayC.is_colliding():
		var center_h = $FeetRayC.get_collision_point().y
		if abs(self.position.y - center_h) > fall_damage_threshold:
			if not self.ragdoll:
				self.ragdoll_now()
			return
		self.position.y = center_h
		if $FeetRayF.is_colliding():
			var front_h = $FeetRayF.get_collision_point().y
			$Armature.rotation.z = sin((front_h - center_h) / 0.2)
		if $FeetRayR.is_colliding():
			var right_h = $FeetRayR.get_collision_point().y
			$Armature.rotation.x = sin((center_h - right_h) / 0.2)
	else:
		if self.tween != null and not self.tween.is_running() and not self.ragdoll:
			self.ragdoll_now()

func reset_tween() -> void:
	self.tween = self.create_tween()
	self.tween.set_trans(Tween.TRANS_SINE)
	self.tween.set_parallel()

func reset() -> void:
	self.transform = start_transform
	$Armature/Skeleton3D.physical_bones_stop_simulation()
	$AnimationPlayer.play(&"ForceReset")
	await $AnimationPlayer.animation_finished
	self.processor.reset()
	self.ragdoll = false

func load_program(program:Array[Parser.ParsedStatement]) -> void:
	self.processor.load_program(program)

func execute() -> bool:
	if self.acting:
		return true
	if self.ragdoll:
		return false
	self.processor.registers[19] = self.lookingAt()
	var res = self.processor.execute()
	if self.processor.registers[18] != 0:
		self.act(self.processor.registers[18])
		self.processor.registers[18] = 0
	return res

func act(op) -> void:
	match op:
		1:
			for b in $Eyes.get_overlapping_bodies():
				if b.collision_mask & 1:
					$AnimationPlayer.play(&"LookAndDeny")
					return
			self.reset_tween()
			self.tween.tween_property(self, ^"position:x", 
					self.position.x+round(cos(rotation.y)), 
					tween_duration)
			self.tween.tween_property(self, ^"position:z", 
					self.position.z-round(sin(rotation.y)), 
					tween_duration)
			self.tween.play()
		2:
			for b in $EyesBack.get_overlapping_bodies():
				if b.collision_mask & 1:
					$AnimationPlayer.play(&"LookAndDeny")
					return
			self.reset_tween()
			self.tween.tween_property(self, ^"position:x",
					self.position.x-round(cos(rotation.y)),
					tween_duration)
			self.tween.tween_property(self, ^"position:z",
					self.position.z+round(sin(rotation.y)),
					tween_duration)
			self.tween.play()
		3:
			# TODO use quaternions or basis
			# self.quaternion.slerp()
			self.reset_tween()
			self.tween.tween_property(self, ^"rotation:y", 
					self.rotation.y - PI/2, 
					tween_duration)
			self.tween.play()
		4:
			self.reset_tween()
			self.tween.tween_property(self, ^"rotation:y", 
					self.rotation.y + PI/2, 
					tween_duration)
			self.tween.play()
		5:
			self.reset_tween()
			self.tween.tween_property(self, ^"rotation:y", 
					self.rotation.y + PI, 
					tween_duration)
			self.tween.play()
		6:
			$AnimationPlayer.play(&"IdleWave")
		_:
			return

func lookingAt():
	for b in $Eyes.get_overlapping_bodies():
		if b.collision_mask & 1:
			return 1
		elif b.collision_mask & 2:
			pass
	return 0

func ragdoll_now():
	print("owie")
	self.ragdoll = true
	$Armature/Skeleton3D.physical_bones_start_simulation()
