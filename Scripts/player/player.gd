extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var state_machine: AnimationNodeStateMachinePlayback = $Knight/AnimationTree["parameters/playback"]

var instant_jump: bool = true

# Make the velocities seperate for the animation player
var vertical_velocity: Vector3 = Vector3.ZERO
var horizontal_velocity: Vector3

func _physics_process(delta: float) -> void:
	horizontal_velocity = Vector3.ZERO

	# Handle jump.
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			vertical_velocity.y = JUMP_VELOCITY
			instant_jump = false
		else:
			vertical_velocity.y = 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		horizontal_velocity.x = direction.x * SPEED
		horizontal_velocity.z = direction.z * SPEED
	else:
		horizontal_velocity.x = move_toward(horizontal_velocity.x, 0, SPEED)
		horizontal_velocity.z = move_toward(horizontal_velocity.z, 0, SPEED)

	# Add the gravity.
	if not is_on_floor():
		vertical_velocity += get_gravity() * delta
		jump(instant_jump)
	elif horizontal_velocity == Vector3.ZERO:
		idle()
	else:
		run()
		
	# Add the seperate velocities back together
	velocity = horizontal_velocity + vertical_velocity

	move_and_slide()

func idle() -> void:
	if state_machine.get_current_node() != "Idle":
		state_machine.travel("Idle")
	
func run() -> void:
	if state_machine.get_current_node() != "Run":
		state_machine.travel("Run")
	
func jump(instant: bool) -> void:
	print(state_machine.get_fading_from_node())
	if state_machine.get_current_node() != "Jump" or state_machine.get_current_node() != "Jump_Start":
		if instant:
			state_machine.start("Jump")
		else:
			state_machine.travel("Jump")
