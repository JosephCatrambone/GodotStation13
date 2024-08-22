extends NPCBehavior

@export var target_thing: Node3D
@export var max_distance: float = 0.4

var move_started: bool = false
var thing_used: bool = false

var move_prefab: PackedScene = preload("res://npc/behaviors/move_to_node.tscn")

func set_target(thing: Node3D):
	assert(thing.has_method("interact"))
	self.target_thing = thing
	self.target_thing.used.connect(self.on_thing_used)

func is_complete():
	return self.thing_used

func is_preemptable():
	return false
	
func on_process(delta: float) -> void:
	# If on_process is called it's because we are currently the focus. Get to the next step.
	if not self.move_started:
		var npc: NPC = self.get_parent()
		var move: NPCBehavior = move_prefab.instantiate()
		move.set_target_position(target_thing.global_position)
		npc.push_behavior(move)
		move.popped.connect(self.on_arrived)
		self.move_started = true

func on_arrived():
	var npc: NPC = self.get_parent()
	print(npc.display_name + " uses " + self.target_thing.name)
	self.target_thing.interact(npc)

func on_thing_used():
	self.thing_used = true
