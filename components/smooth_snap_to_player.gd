extends Component

@export var lookahead: float = 0.0
@export var speed: float = 1.0
@export var subject_to_follow: Node3D
@export var position_offset_from_subject: Vector3 = Vector3(0.0, 3.0, 1.0)
@export var look_offset_from_subject: Vector3 = Vector3(0.0, 1.0, 0.0)
var subject_previous_position: Vector3 = Vector3.ZERO

func _process(delta):
	if subject_to_follow != null and is_instance_valid(subject_to_follow):
		var to_move: Node3D = self.get_parent()
		
		var subject_current_position = subject_to_follow.global_position
		var subject_velocity_vector = subject_current_position - subject_previous_position
		subject_previous_position = subject_current_position
		
		var lookahead_offset = subject_velocity_vector * lookahead * delta
		var target_position = subject_current_position + position_offset_from_subject
		
		# Our lookahead should only move the camera to the position ahead.  The look angle should still be locked.
		to_move.global_position = lerp(to_move.global_position, target_position, speed*delta)
		to_move.global_transform = to_move.global_transform.interpolate_with(to_move.global_transform.looking_at(subject_current_position + lookahead_offset + look_offset_from_subject), speed*delta)
		#to_move.translate()  # This will fail because we may be rotated.
