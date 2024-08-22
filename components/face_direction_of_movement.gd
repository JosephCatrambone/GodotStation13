extends Component

var previous_position: Vector3

func _process(delta: float) -> void:
	# TODO: This whole approach isn't great.  Find something smarter.
	
	var p = self.get_parent()
	if p.is_class("CharacterBody3D") or p.is_class("RigidBody3D"):
		# This multiplies by delta, so the speed needs to be much higher.
		var p2: CharacterBody3D = p
		#var direction = atan2(p2.velocity.z, p2.velocity.x)
		if p2.velocity.length_squared() > 1e-6:
			p2.global_transform = p2.global_transform.looking_at(self.global_position - p2.velocity)
	elif p.is_class("PhysicsBody3D"):
		var p2: PhysicsBody3D = p
		if p2.motion.length_squared() > 1e-6:
			p2.global_transform = p2.global_transform.looking_at(self.global_position - p2.motion)
	elif p.is_class("Node3D"):
		var p2: Node3D = p
		var delta_position = p2.global_position - previous_position
		if delta_position.length_squared() > 1e-6:
			p2.global_transform = p2.global_transform.looking_at(self.global_position - delta_position)
		self.previous_position = p2.global_position
