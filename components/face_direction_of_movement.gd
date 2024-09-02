extends Component

var enable: bool = true
var previous_position: Vector3
var ignore_delta_y: bool = true

func _process(delta: float) -> void:
	# TODO: This whole approach isn't great.  Find something smarter.
	if not self.enable:
		return
	
	var p = self.get_parent()
	var look_shift: Vector3
	if p.is_class("CharacterBody3D") or p.is_class("RigidBody3D"):
		# This multiplies by delta, so the speed needs to be much higher.
		var p2: CharacterBody3D = p
		#var direction = atan2(p2.velocity.z, p2.velocity.x)
		look_shift = p2.velocity
	elif p.is_class("PhysicsBody3D"):
		var p2: PhysicsBody3D = p
		look_shift = p2.motion
	elif p.is_class("Node3D"):
		var p2: Node3D = p
		var delta_position = p2.global_position - previous_position
		look_shift = delta_position
		self.previous_position = p2.global_position
	
	if self.ignore_delta_y:
		look_shift.y = 0.0
	
	if look_shift.length_squared() > 1e-6:
		p.global_transform = p.global_transform.looking_at(self.global_position - look_shift)
