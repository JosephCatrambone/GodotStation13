extends NPCBehavior

@export var center: Vector3 = Vector3(0, 0, 0)
@export var max_distance: float = 5.0
@export var duration: float = -1  # If less than zero, wander indefinitely.
var wander_start: float = Time.get_unix_time_from_system()

var wander_prefab: PackedScene = preload("res://npc/behaviors/move_to_node.tscn")

func is_complete():
	if duration < 0.0:
		return false  # Endless
	var now = Time.get_unix_time_from_system()
	return (now - wander_start) > duration

func is_preemptable():
	return true
	
func on_process(delta: float) -> void:
	# If on_process is called it's because we are currently the focus, so pick a new place to move to and push that on top of events.
	# TODO: It might be better to have a way to signal that we want a new state, but for now...
	var npc: NPC = self.get_parent()
	var dest = center + Vector3(randf_range(-max_distance, max_distance), 0, randf_range(-max_distance, max_distance))
	var wander: NPCBehavior = wander_prefab.instantiate()
	wander.set_target_position(dest)
	npc.push_behavior(wander)
