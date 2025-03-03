extends CharacterBody3D

@onready var player: CharacterBody3D = $"../player"

@onready var animation_tree: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

const SPEED = 8
const ACCELERATION = 15

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var direction: Vector3 = global_position.direction_to(player.companion_target_position.global_position)
	direction.y = 0
	look_at(position + direction)
	if global_position.distance_to(player.companion_target_position.global_position) > 0.1:
		velocity = direction * SPEED * delta * ACCELERATION
		run()
	else:
		velocity = Vector3.ZERO
		idle()
	move_and_slide()

func run() -> void:
	animation_tree.travel("Run")
	
func idle() -> void:
	animation_tree.travel("Idle")
