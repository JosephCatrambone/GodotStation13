extends Node

@export var rotation_speed: float = 4.0
var tween: Tween

func _process(delta: float) -> void:
	var p: Node3D = self.get_parent()
	
	if not self._rotation_active():
		if Input.is_action_just_pressed("rotate_left"):
			var start_rotation = p.global_rotation
			tween = get_tree().create_tween()
			tween.tween_property(p, "global_rotation", start_rotation - Vector3(0, PI*0.5, 0), 1.0/rotation_speed)
		if Input.is_action_just_pressed("rotate_right"):
			var start_rotation = p.global_rotation
			tween = get_tree().create_tween()
			tween.tween_property(p, "global_rotation", start_rotation + Vector3(0, PI*0.5, 0), 1.0/rotation_speed)

func _rotation_active():
	return tween != null and is_instance_valid(tween) and tween.is_running()
