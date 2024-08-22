class_name Desire extends Node3D

@export var raw_desire: float = 0.0  # A float between 0 and 1 that grows until it hits one.
@export var desire_name: String = ""  # Interactables will advertise this.
@export var growth_rate: float = 0.1
@export var motivation_scale: Curve
@export var happiness_scale: float = -1.0  # A number, probably +1 or -1, to impact happiness.  High happiness = good, so if this grows towards +1 and this trait is BAD...

func _process(delta):
	self.raw_desire = clampf(delta*self.growth_rate+self.raw_desire, 0.0, 1.0)

func get_net_happiness() -> float:
	return self.raw_desire*self.happiness_scale

func get_estimated_happiness(delta_value: float):
	return (self.raw_desire + delta_value)*self.happiness_scale

func get_motivation_score() -> float:
	# Returns a number, positive or negative, which says how much a person wants to do this.
	# A higher number means they want to do it more.
	return self.motivation_scale.sample_baked(self.raw_desire)
