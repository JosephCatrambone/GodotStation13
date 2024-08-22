class_name Sight extends Area3D

signal entered_fov(actor)
signal detected(actor)

@export var reaction_time: float = 0.85
var actors_in_fov: Dictionary = {}  # Actor -> time until detection.
var detected_actors: Array = []

func _ready() -> void:
	self.body_entered.connect(_on_actor_entered_vision)
	self.body_exited.connect(_on_actor_leaves_vision)

func _physics_process(delta: float) -> void:
	var space_state = get_world_3d().direct_space_state
	for actor in self.actors_in_fov.keys():
		if self.actors_in_fov[actor] > 0:
			var query = PhysicsRayQueryParameters3D.create(self.global_position, actor.global_position, 1|2)
			query.exclude = [self,]
			var result = space_state.intersect_ray(query)
			if result.has("collider") and result["collider"] == actor:
				self.actors_in_fov[actor] -= delta
				if self.actors_in_fov[actor] < 0:
					self.detected_actors.append(actor)
					emit_signal("detected", actor)
					print("Detected actor")
			else:
				self.actors_in_fov[actor] = min(reaction_time, self.actors_in_fov[actor]+delta)
				self._remove_actor_from_detected_actors(actor)
				

func _on_actor_entered_vision(body: PhysicsBody3D):
	if not self.actors_in_fov.has(body):
		self.actors_in_fov[body] = self.reaction_time
		print("Actor may be in FOV")

func _on_actor_leaves_vision(body: PhysicsBody3D):
	if self.actors_in_fov.has(body):
		self.actors_in_fov.erase(body)
		print("Actor has left fov")
	self._remove_actor_from_detected_actors(body)

func _remove_actor_from_detected_actors(actor):
	var detected_idx = self.detected_actors.find(actor)
	if detected_idx != -1:
		self.detected_actors.remove_at(detected_idx)
