extends NPCBehavior

@export var wait_duration: float = 1.0
var time_waited: float = 0.0

func is_complete() -> bool:
	# Returns 'true' when the task is completed.
	# If a task loops endlessly this might always return false, so check if it's preemptable.
	return self.time_waited > wait_duration

func is_preemptable() -> bool:
	return false

func on_process(delta: float):
	self.time_waited += delta
	
