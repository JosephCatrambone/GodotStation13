class_name Interactive extends Node3D

@export var provides: String
@export var amount: float

signal used  # Called somewhere between start of use and end of use.
signal on_start_using  # Called when an actor starts using a thing.
signal on_finish_using  # Called when an actor/npc finishes using a thing.

func interact(who: Node):
	self.emit_signal("on_start_using")
	self.emit_signal("used")
	if who.has_method("satisfy_desire"):
		who.satisfy_desire(self.provides, self.amount)
	self.emit_signal("on_finish_using")
	
