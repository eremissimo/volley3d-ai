class_name VolleyField extends Node3D

signal export_state(state: Dictionary)
signal game_reset(winner_side: int)

static var max_id: int = -1
var id: int = 0
static var field_size := [21.0, 11.0]	# field size in game engine meters
static var state_size := 21	# also neural network input size
static var action_size := 5		# also neural network output size
const update_state_delta := 0.1	# in seconds
var delta_counter := 0.0	# in seconds
@onready var ball := $Ball
@onready var left_player: Player = $PlayerLeft
@onready var right_player: Player = $PlayerRight
var transitions: Array[Dictionary] = []

# as for now ready_for_send is triggered by a timer
# this behaviour will be changed soon
var TMP_delta_counter := 0.0	# in seconds
const TMP_send_delta := 1.0	# in seconds

func _init():
	self.max_id += 1
	id = max_id

func _ready():
	ball.connect("ball_on_ground", _reset_signal_retranslator)
	ball.connect("more_than_three_touches", _reset_signal_retranslator)

func _physics_process(delta):
	# update state every update_state_delta seconds
	if ready_for_update(delta):
		update_state()
	if ready_to_send(delta):
		send_transitions()

func ready_for_update(delta) -> bool:
	delta_counter += delta
	if delta_counter > update_state_delta:
		delta_counter = 0.0
		return true
	return false
	
func ready_to_send(delta) -> bool:
	TMP_delta_counter += delta
	if TMP_delta_counter > TMP_send_delta:
		TMP_delta_counter = 0.0
		return true
	return false

func update_state():
	var state = {"ball_pos":ball.position, 
				 "ball_vel":ball.linear_velocity, 
				 "ball_ang":ball.angular_velocity,
				 "lplayer_pos": left_player.position,
				 "lplayer_vel": left_player.velocity,
				 "rplayer_pos": right_player.position,
				 "rplayer_vel": right_player.velocity}
	export_state.emit(state)

func gather_transitions_from_aicontrollers():
	var d: Dictionary
	if left_player.controller is AIController:
		d = left_player.controller.consume_transitions()
		d["field_id"] = id
		transitions.append(d)
	if right_player.controller is AIController:
		d = right_player.controller.consume_transitions()
		d["field_id"] = id
		transitions.append(d)
	
func send_transitions():
	# TODO
	gather_transitions_from_aicontrollers()
	transitions.clear()	
	
func _reset_signal_retranslator(winner_side: int):
	# combines 'ball_on_ground' and 'more_than_three_touches'
	# signals from the ball and emits 'game_reset'
	game_reset.emit(winner_side)
	
func get_env_info() -> Dictionary:
	var env_info := {"field_id": id, 
					 "lplayer_id": left_player.id,
					 "rplayer_id": right_player.id}
	return env_info
	
func pause():
	process_mode = PROCESS_MODE_DISABLED

func unpause():
	process_mode = PROCESS_MODE_INHERIT
