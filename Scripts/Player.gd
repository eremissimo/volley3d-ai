class_name Player extends CharacterBody3D


enum Sides {Right=-1, Left=1}
enum ControlType {Player, Bot}
enum ControlView {SideView, FrontView}
# ControlView switches between WASD input (where W moves body towards the net)
# for the FrontView and DWAS input (where D moves towards the net) for side view

@export_group("Player Properties")
@export var side: Sides
@export var control := ControlType.Player 
@export var control_from := ControlView.SideView
@export_range(0, 20, 0.1) var speed: float = 5.0
@export_range(0, 20, 0.1) var jump_speed: float = 8.0
var controller: Controller
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var id

func _ready():
	position = Vector3(-float(side)*5.5, 0.8, 0.0)
	var shp := $VisibleShape
	shp.material = StandardMaterial3D.new()
	shp.material.set_albedo(Color.from_hsv(randf(),1.,1.))
	if control == ControlType.Bot:
		# bots are controlled from the frontal view
		control_from = ControlView.FrontView
		controller = AIController.new(int(side), $"..")
		id = controller.id
	else: 
		controller = ManualController.new(int(side))
		id = null

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if controller.jumped() and is_on_floor():
		velocity.y = jump_speed

	# Get the input direction and handle the movement/deceleration.
	var input_dir = controller.input_direction()
	var sign_coeff := 1.0
	if control_from == ControlView.SideView:
		input_dir = input_dir.rotated(-0.5*PI)
	else:
		# from the front view controls are inverted depending on the 'side'
		sign_coeff = float(side)
	var direction = sign_coeff*(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func get_input_direction_manual() -> Vector2:
	var dir: Vector2
	if side == Sides.Left:
		dir = Input.get_vector("left_player_down", "left_player_up", 
		"left_player_left", "left_player_right")
	else:
		dir = Input.get_vector("right_player_down", "right_player_up", 
		"right_player_left", "right_player_right")
	return dir

func jumped_manual() -> bool:
	return (Input.is_action_just_pressed("left_player_jump") if
		(side == Sides.Left) else Input.is_action_just_pressed("right_player_jump"))

func manual_control():
	pass
	
