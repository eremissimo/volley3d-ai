class_name ManualController extends Controller
# a keyboard-mouse player input handler

func _init(side_):
	super(side_)

func jumped() -> bool:
	return (Input.is_action_just_pressed("left_player_jump") if
		(side == 1) else Input.is_action_just_pressed("right_player_jump"))

func input_direction() -> Vector2:
	var dir: Vector2
	if side == 1:
		dir = Input.get_vector("left_player_down", "left_player_up", 
		"left_player_left", "left_player_right")
	else:
		dir = Input.get_vector("right_player_down", "right_player_up", 
		"right_player_left", "right_player_right")
	return dir

