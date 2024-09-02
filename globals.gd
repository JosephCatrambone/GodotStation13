extends Node

var player: Node3D
signal player_spawned(Node3D)

func get_components(actor: Node, include_children: bool) -> Array[Component]:
	"""Given an actor, return all of the components on it.
	If include_children is true, will returse into all child components to find those components, too.
	"""
	# I'm not comfortable using the inital value of [] in the constructor because there's a Python thing where it creates a default object and that's a possible footgun.
	# It may be possible to optimize/clean the code to do this but I need to check.
	return _get_components_recursive(actor, include_children, [])

func _get_components_recursive(actor: Node, include_children: bool, components: Array) -> Array[Component]:
	var unprocessed = actor.get_children(true)
	for c in unprocessed:
		if c.is_class("Component"):
			components.append(c)
		if include_children:
			_get_components_recursive(c, include_children, components)
	return components
	
func weighted_random_choice_of_elements(arr: Array):
	# Given a list of [[value, thing], ...], where the 0th element of each item is the probability, select one.
	var total = 0.0
	for v in arr:
		total += v[0]
	var energy = randf()*total
	for v in arr:
		if v[0] > energy:
			return v
		energy -= v[0]
	return arr[-1]  # Should never get here.
