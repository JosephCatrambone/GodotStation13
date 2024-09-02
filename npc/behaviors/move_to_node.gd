extends NPCBehavior

const WALK_ANIM_NAME = "walk"
const STUCK_TIME_DELAY: float = 3.0

var move_paused: bool = false
var target_position_to_set  # IF THIS IS NONE THEN NAV_AGENT IS SET!  Otherwise we have to wait for nav agent to become non-null so we can set it.
var nav_agent: NavigationAgent3D
var previous_position: Vector3
var previous_velocity: Vector3 = Vector3.ZERO
var stuck_time_delay: float = STUCK_TIME_DELAY  # How long should we wait before considering ourselves stuck?
var back_and_forth_velocity_snap_count: int = 0  # How many times have we gone from +xyz to -xyz?  If we're rapidly switching back and forth we might be stuck around a node.

var nav_agent_reported_completion: bool = false  # We set this to true when the nav agent says we're done.

# We have to do all kinds of funky things with != null here because nav_agent isn't always ready.
signal destination_reached
signal stuck

func _enter_tree() -> void:
	super()
	self.move_paused = false

func _exit_tree() -> void:
	self.move_paused = true

func is_complete():
	if nav_agent == null or not is_instance_valid(nav_agent):
		return false
	var complete = nav_agent.is_navigation_finished() and self.target_position_to_set == null
	if (complete and not self.nav_agent_reported_completion) or (not complete and self.nav_agent_reported_completion):
		printerr("Nav agent and nav agent disagree: ")
		printerr(self.complete)
		printerr(self.nav_agent_reported_completion)
	return complete

func set_target_position(target_position: Vector3):
	if self.nav_agent != null:
		self.nav_agent.set_target_position(target_position)
		self.target_position_to_set = null
	else:
		self.target_position_to_set = target_position

func on_process(delta):
	if self.nav_agent == null:
		self.nav_agent = self.get_parent().nav_agent
		if self.nav_agent != null:
			self.nav_agent.velocity_computed.connect(self._on_velocity_computed)
			#self.nav_agent.navigation_finished.connect(self._on_destination_reached())
			self.nav_agent.target_reached.connect(self._on_destination_reached)
	if self.target_position_to_set != null:
		self.set_target_position(self.target_position_to_set)

func _ready():
	#self.nav_agent = self.get_parent().nav_agent
	self.previous_position = self.get_parent().global_position

func on_physics_process(delta: float) -> void:
	if self.nav_agent == null or self.move_paused:
		return
	if not self.nav_agent.is_navigation_finished():
		var current_agent_position: Vector3 = self.npc.global_position
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		var new_direction = current_agent_position.direction_to(next_path_position)
		#var new_velocity = Vector3(new_direction.x, 0, new_direction.z).normalized() * self.npc.movement_speed
		var new_velocity = new_direction.normalized() * self.npc.movement_speed
		self.nav_agent.velocity = new_velocity  # To keep safe paths in sync.
		# We have to rely on the nav agent to set the velocity or else it won't avoid other NPCs.
		#npc.velocity = new_velocity
		#npc.move_and_slide()
		if self.npc.velocity.length_squared() > 1e-3 and (current_agent_position - self.previous_position).length() < 1e-3:
			self.stuck_time_delay -= delta  # We are trying to move but we can't.
			if self.stuck_time_delay <= 0.0:
				self._on_stuck()
		else:
			self.stuck_time_delay = STUCK_TIME_DELAY
		self.previous_position = current_agent_position

func _on_velocity_computed(new_velocity: Vector3):
	if self.move_paused:
		return
	
	# Check to see if we're rapidly moving back and forth around a point.
	if (-new_velocity).distance_to(self.previous_velocity) < 1e-3:
		self.back_and_forth_velocity_snap_count += 1
		if self.back_and_forth_velocity_snap_count > 10:
			self._on_path_looping()
			return
	else:
		self.back_and_forth_velocity_snap_count = 0
	previous_velocity = new_velocity
		
	self.npc.velocity = new_velocity
	self.npc.move_and_slide()
	if new_velocity.length_squared() > 1e-3:
		self.npc.anim_player.play(WALK_ANIM_NAME)

func _on_destination_reached():
	self.nav_agent_reported_completion = true

func _on_stuck():
	emit_signal("stuck")
	self.npc.global_position = self.nav_agent.get_final_position()

func _on_path_looping():
	"""The path has us moving back and forth rapidly around the same point."""
	print("Velocity has snapped to +/- " + str(self.previous_velocity) + " 10 times.")
	print("Currently at " + str(self.npc.global_position))
	print("Trying to reach " + str(self.nav_agent.target_position))
	print("Next waypoint at " + str(self.nav_agent.get_next_path_position()))
	print("Nav finished: " + str(self.nav_agent.is_navigation_finished()))
	print("Nav target reached: " + str(self.nav_agent.is_target_reached()))
	print("Distance to target according to nav_agent: " + str(self.nav_agent.distance_to_target()))
	var dist_to_next_path_position = self.npc.global_position.distance_to(self.nav_agent.get_next_path_position())
	print("Distance to next path position: " + str(dist_to_next_path_position))
	var dist_to_target_position = self.npc.global_position.distance_to(self.nav_agent.target_position)
	print("Distance to target position: " + str(dist_to_target_position))
	# This doesn't work.
	#self.global_position = self.nav_agent.get_next_path_position()
	self.back_and_forth_velocity_snap_count = 0
