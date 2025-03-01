extends CharacterBody3D

@onready var player_mesh = get_node("Knight")

@export var gravity: float = 9.8
@export var jump_force: int = 9
@export var walk_speed: int = 3
@export var run_speed: int = 10

#animation node names
var idle_node_name: String = "Idle"
var walk_node_name: String = "Walk"
var run_node_name: String = "Run"
var jump_node_name: String = "Jump"
var attack1_node_name: String = "Attack1"
var death_node_name: String = "Death"

#State Machine Conditions
var is_attacking: bool
var is_walking: bool
var is_running: bool
var is_dying: bool

#physics values
var direction: Vector3
var horizontal_velocity: Vector3
var aim_turn: float
var movement: Vector3
var vertical_velocity: Vector3
var movement_speed: int
var angular_acceleration: int
var acceleration: int
var just_hit: bool

@onready var camrot_h = get_node("camroot/h")

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
		
	if event.is_action_pressed("aim"):
		direction = camrot_h.global_transform.basis.z

@onready var state_machine: AnimationNodeStateMachinePlayback = $Knight/AnimationTree["parameters/playback"]

var instant_jump: bool = true

# Make the velocities seperate for the animation player
var vertical_velocity: Vector3 = Vector3.ZERO
var horizontal_velocity: Vector3

func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()
	
	if !is_dying:
		if !on_floor:
			vertical_velocity += Vector3.DOWN*gravity*2*delta
		else:
			vertical_velocity = Vector3.DOWN*gravity/10
		if Input.is_action_just_pressed("jump") and (!is_attacking) and on_floor:
			vertical_velocity = Vector3.UP * jump_force
		angular_acceleration = 10
		movement_speed = 0
		acceleration = 15
		var h_rot = camrot_h.global_transform.basis.get_euler().y
		if (Input.is_action_pressed("forward") or Input.is_action_pressed("backward") or Input.is_action_pressed("left") or Input.is_action_pressed("right")):
			direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
								0,
								Input.get_action_strength("forward") - Input.get_action_strength("backward"))
									
			direction = direction.rotated(Vector3.UP, h_rot).normalized()
			if Input.is_action_pressed("sprint") and (is_walking):
				movement_speed = run_speed
				is_running = true
			else:
				is_walking = true
				movement_speed = walk_speed
		else:
			is_walking = false
			is_running = false
		if Input.is_action_pressed("aim"):
			player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, camrot_h.rotation.y, delta*angular_acceleration)
		else:
			player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta*angular_acceleration)
		
		if is_attacking: 
			horizontal_velocity = horizontal_velocity.lerp(direction.normalized()*0.01, acceleration * delta)
		else:
			horizontal_velocity = horizontal_velocity.lerp(direction.normalized()*movement_speed, acceleration * delta)
		velocity.z = horizontal_velocity.z + vertical_velocity.z
		velocity.x = horizontal_velocity.x + vertical_velocity.x
		velocity.y = vertical_velocity.y
		move_and_slide()
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
