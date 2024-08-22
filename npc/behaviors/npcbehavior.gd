class_name NPCBehavior extends Node3D

signal popped  # Emitted via the _parent managing class_(!!!) calling this.emit_signal("popped") when this is popped.

func is_complete() -> bool:
	# Returns 'true' when the task is completed.
	# If a task loops endlessly this might always return false, so check if it's preemptable.
	return false
	

func is_preemptable() -> bool:
	# Returns 'true' if it is okay to terminate this task in the middle.
	# For example: 'idle' would be fine to terminate in the middle, while 'wait' would not be.
	# Note that preemptable is not the same as interruptable.
	# If something is preempted we expect to REMOVE IT AND NEVER HAVE IT FINISH.
	# Interruptable means that we can put something in front to do first.
	return true

#func on_preempted():
#	pass

#func on_resumed():
#	pass

# The node scripts will be called by the engine, so we should implement these instead.
func on_physics_process(delta: float) -> void:
	pass

func on_process(delta: float) -> void:
	pass
