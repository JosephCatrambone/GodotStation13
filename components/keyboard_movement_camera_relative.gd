extends Component

@export var walk_speed: float = 1.0
@export var can_run: bool = true
@export var run_speed: float = 2.0


func _process(delta: float) -> void:
	var dx = Input.get_axis("move_left", "move_right")
	var dy = Input.get_axis("move_down", "move_up")
	
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	
	# Note: if there's a camera latency or it looks left/right, this might not behave as expected.
	var projected_movement: Vector3 = -cam.global_transform.basis.z * dy + cam.global_transform.basis.x * dx
	projected_movement.y = 0
	var movement_vector = projected_movement.normalized()
	
	var speed = self.walk_speed
	if Input.is_action_pressed("run"):
		speed = self.run_speed
	
	var p = self.get_parent()
	if p.is_class("CharacterBody3D") or p.is_class("RigidBody3D"):
		# This multiplies by delta, so the speed needs to be much higher.
		var p2: CharacterBody3D = p
		p2.velocity = movement_vector * speed
		p2.move_and_slide()
	elif p.is_class("PhysicsBody3D"):
		var p2: PhysicsBody3D = p
		p2.move_and_collide(movement_vector * speed)
	elif p.is_class("Node3D"):
		var p2: Node3D = p
		p2.global_translate(movement_vector * delta * speed)
		
