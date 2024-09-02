class_name Interactive extends Node3D

@export var provides: String
@export var amount: float
@export var use_time: float = 0.5
@export var max_use_distance: float = 1.0

signal used  # Called somewhere between start of use and end of use.
signal on_start_using  # Called when an actor starts using a thing.
signal on_finish_using  # Called when an actor/npc finishes using a thing.

func interact(who: Node):
	var tmp = self.provides
	self.provides = ""  # While something is using this, don't broadcast that anything is provided.
	self.emit_signal("on_start_using")
	self.emit_signal("used")
	if who.has_method("satisfy_desire"):
		who.satisfy_desire(self.provides, self.amount)
	await get_tree().create_timer(self.use_time).timeout
	self.emit_signal("on_finish_using")
	self.provides = tmp
	
