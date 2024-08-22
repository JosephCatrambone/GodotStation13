extends Component

@export var movement_speed: float = 1.0
@export var right: Vector3 = Vector3(1.0, 0.0, 0.0)
@export var forward: Vector3 = Vector3(0.0, 0.0, -1.0)


func _process(delta: float) -> void:
	var dx = Input.get_axis("move_left", "move_right")
	var dy = Input.get_axis("move_down", "move_up")
	
	var movement_vector = right*dx + forward*dy
	
	var p = self.get_parent()
	if p.is_class("CharacterBody3D") or p.is_class("RigidBody3D"):
		# This multiplies by delta, so the speed needs to be much higher.
		var p2: CharacterBody3D = p
		p2.velocity = movement_vector * movement_speed
		p2.move_and_slide()
	elif p.is_class("PhysicsBody3D"):
		var p2: PhysicsBody3D = p
		p2.move_and_collide(movement_vector * movement_speed)
	elif p.is_class("Node3D"):
		var p2: Node3D = p
		p2.global_translate(movement_vector * delta * movement_speed)
		
	
