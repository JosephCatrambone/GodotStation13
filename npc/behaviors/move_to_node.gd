extends NPCBehavior

const STUCK_TIME_DELAY: float = 3.0

var target_position_to_set  # IF THIS IS NONE THEN NAV_AGENT IS SET!  Otherwise we have to wait for nav agent to become non-null so we can set it.
var movement_speed: float = 1.0
var nav_agent: NavigationAgent3D
var previous_position: Vector3
var stuck_time_delay: float = STUCK_TIME_DELAY  # How long should we wait before considering ourselves stuck?

# We have to do all kinds of funky things with != null here because nav_agent isn't always ready.

func is_complete():
	if nav_agent == null or not is_instance_valid(nav_agent):
		return false
	var complete = nav_agent.is_navigation_finished() and self.target_position_to_set == null
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
	if self.target_position_to_set != null:
		self.set_target_position(self.target_position_to_set)

func _ready():
	self.nav_agent = self.get_parent().nav_agent
	self.previous_position = self.get_parent().global_position

func on_physics_process(delta: float) -> void:
	if self.nav_agent == null:
		return
	if not nav_agent.is_navigation_finished():
		var npc: NPC = self.get_parent()
		var current_agent_position: Vector3 = npc.global_position
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		npc.velocity = current_agent_position.direction_to(next_path_position) * movement_speed
		npc.move_and_slide()
		if npc.velocity.length_squared() > 1e-3 and (current_agent_position - self.previous_position).length() < 1e-3:
			self.stuck_time_delay -= delta  # We are trying to move but we can't.
			if self.stuck_time_delay <= 0.0:
				print("Stuck")
		else:
			self.stuck_time_delay = STUCK_TIME_DELAY
		self.previous_position = current_agent_position
