class_name NPC extends CharacterBody3D

@export var display_name: String = "Someone"
@export var movement_speed: float = 1.0
@onready var sight: Sight = $SightArea

var behavior_stack: Array = []  # We only _process the top one of these.  The LAST element is current for performance reasons.  Pop/push.
# Movement to and participation in activity.
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var current_activity: Node3D
var target_activity: Node3D
var debug_pause_at_dest: float = 1.0

var debug_desires: bool = false
var debug_last_print: float = 0.0
@export var select_from_k_activities: int = 3  # At a higher value, an NPC will be less rational. Pick at random between this many.
@export var weighted_activity_selection: bool = true  # Weight activity selection by urgency, rather than pure random.
@export var max_distance_to_usable_object: float = 1000.0
@onready var desires: Node3D = $Desires
var happiness: float = 0.0

@onready var overhead_text: Label3D = $Label3D
@onready var anim_player: AnimationPlayer = $Body/AnimationPlayer

func _ready():
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	#call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# Now that the navigation map is no longer empty, set the movement target.
	#set_movement_target(movement_target_position)

func _physics_process(delta):
	var b: NPCBehavior = self.get_behavior_or_null()
	if b != null:
		b.on_physics_process(delta)
	
func _process(delta: float):
	self.update_desires(delta)
	self.update_behaviors(delta)  # Open question: when to do this?

func update_desires(delta: float):
	self.debug_last_print -= delta
	var print_debug_desire = false
	if self.debug_desires and self.debug_last_print < 0:
		self.debug_last_print = 1.0
		print_debug_desire = true
		self.overhead_text.text = ""
	
	self.happiness = 0.0
	var possible_activities = []
	for c in self.desires.get_children(false):
		var c2: Desire = c
		self.happiness += c2.get_net_happiness()
		possible_activities.append([c2.get_motivation_score(), c2.desire_name])
		if print_debug_desire:
			self.overhead_text.text += self.display_name + " -- Desire:" + c2.desire_name + "  Motivation:" + str(c2.get_motivation_score()) + "\n"
	if print_debug_desire:
		self.overhead_text.text += self.display_name + " happiness: " + str(self.happiness) + "\n"
	
	if not self.behavior_stack.is_empty():
		return  # We're in the middle of something.
	
	# Find nearby actions.
	# We end up with a map between 'provided' and the objects that provide them.
	var all_interactive_objects = get_tree().get_nodes_in_group("interactive")
	var available_provided = {}  # Hack: dict ~= set.  Quickly remove unavailable provided from options.
	for obj in all_interactive_objects:
		var dist_to_obj = (obj.global_position - self.global_position).length()
		if dist_to_obj < self.max_distance_to_usable_object:
			if available_provided.has(obj.provides):
				# Maybe swap, weighted by distance?  Use closer one?
				var dist_to_old = (available_provided[obj.provides].global_position - self.global_position).length()
				if dist_to_obj < dist_to_old:
					available_provided[obj.provides] = obj
			else:
				available_provided[obj.provides] = obj
	
	# Remove the things we can't get from the possible activities:
	# If there's nothing to do, do nothing!
	var activities_to_keep = []
	for act in possible_activities:
		if available_provided.has(act[1]):
			activities_to_keep.append(act)
	possible_activities = activities_to_keep
	if len(possible_activities) == 0:
		return
	
	# Select at random between the top K activities.
	# We end up with 'activity_name', chosen at random from the possible_activities.
	possible_activities.sort_custom(func(a, b): return a[0] > b[0])
	possible_activities = possible_activities.slice(0, self.select_from_k_activities)
	var activity_name: String
	if self.weighted_activity_selection:
		var temp = Globals.weighted_random_choice_of_elements(possible_activities)
		activity_name = temp[1]
		if print_debug_desire:
			self.label.text += "Chose activity " + activity_name + " with weight " + str(temp[0]) + "\n"
	else:
		activity_name = possible_activities.pick_random()[1]
	
	# Now we know _what_ we're doing, but need to pick which of the things to use.
	# TODO: Some kind of calculation using the desire's estimate tool.  For now: random.
	var new_action: NPCBehavior = load("res://npc/behaviors/move_to_and_use.tscn").instantiate()
	new_action.set_target(available_provided[activity_name])
	self.push_behavior(new_action)
	if print_debug_desire:
		print(self.display_name + " desires " + activity_name + " .  Moving to " + str(available_provided[activity_name]))
	return

func satisfy_desire(desire_name: String, amount: float):
	for d in self.desires.get_children(true):
		var d2: Desire = d
		if d2.desire_name == desire_name:
			d2.raw_desire += amount

func update_behaviors(delta: float):
	var b: NPCBehavior = self.get_behavior_or_null()
	if b != null:
		if b.is_complete():  # This is either-or because the on_process might push a node.
			var popped = self.behavior_stack.pop_back()
			assert(popped == b)
			b.emit_signal("popped")  # NOTE: If a behavior used get_parent() in popped then it will be null.
			self.remove_child(popped)
			popped.queue_free()
			# Maybe put the previous top back as a child.
			if not self.behavior_stack.is_empty():
				self.add_child(self.behavior_stack.back())
		else:
			b.on_process(delta)
	else:
		self.on_behavior_stack_empty()

func push_behavior_name(packed_behavior_path: String):
	var b: NPCBehavior = load(packed_behavior_path).instantiate()
	self.push_behavior(b)

func push_behavior(b: NPCBehavior):
	# Adds a new behavior to the list.  Does not do the logic checking to see if the previous task should be removed.
	# DOES remove other nodes from child status to prevent the methods from being called.
	for current_child_behavior in self.behavior_stack:
		self.remove_child(current_child_behavior)
	self.add_child(b)
	self.behavior_stack.push_back(b)

func get_behavior_or_null():
	if self.behavior_stack.is_empty():
		return null
	return self.behavior_stack.back()

func on_behavior_stack_empty():
	# It would be nice to be able to do this some day:
	#var b: NPCBehavior = Node3D.new()
	#b.set_script("res://npc/behaviors/idle.gd")
	
	# This is one option: have 'idle' do the activity picking?
	#self.push_behavior_name("res://npc/behaviors/idle.tscn")
	pass
