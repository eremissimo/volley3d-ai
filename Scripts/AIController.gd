class_name AIController extends Controller
# This class generates action = MLP(state) and saves the transitions to
# trans_data storage

signal transitions_storage_full

static var max_id: int = 0
var id: int = -1
const action_size = 5
var state_size: int
var brain: MLP
var action := {"left": false, 
			   "right": false, 
			   "forward": false, 
			   "backward": false,
			   "jump": false}
var trans_data: Dictionary				# transitions data storage
var pending_transition : Dictionary
var trans_data_capacity: int = 1

# left player view
const direction_mapping := {"left": Vector2(0.0, -1.0),
							"right": Vector2(0.0, 1.0),
							"forward": Vector2(1.0, 0.0),
							"backward": Vector2(-1.0, 0.0)}

func _init(side_: int, volley_field: Node3D, 
	n_hidden_layers: int = 2, hidden_size: int = 32, 
	trans_data_max_size: int = 1):
	super(side_)
	max_id += 1
	id = max_id
	
	volley_field.connect("export_state", _on_state_updated)
	volley_field.connect("game_reset", _on_game_reset)
	
	state_size = volley_field.state_size
	var hiddens: Array[int] = []
	hiddens.resize(n_hidden_layers)
	hiddens.fill(hidden_size)
	brain = MLP.new(state_size, action_size, hiddens)
	
	trans_data = {"player_id": id, "side": side, "transitions": []}
	self.trans_data_capacity = trans_data_max_size
	
func jumped() -> bool:
	return action["jump"]

func input_direction() -> Vector2:
	var dir = Vector2.ZERO
	for key in direction_mapping.keys():
		if action[key]:
			dir += direction_mapping[key]
	return dir.normalized()
	
func _on_state_updated(state:Dictionary):
		# state inverts depending on the side
	var input: Array[float] = []
	for v in state.values():
		input.append(side*v.x)
		input.append(side*v.y)
		input.append(side*v.z)
	var pred: PackedFloat64Array = brain.forward(input)
	save_actions(pred)
	# "done" and "reward" will be overriden on game reset signals
	save_transition({"state": input, "action": pred, "reward": 0.0, "done": false})
	
func save_actions(pred: PackedFloat64Array):
	var i: int = 0
	for key in action.keys():
		action[key] = pred[i] > 0.0 
		i += 1

func save_transition(transition: Dictionary):
	# saving pending transition to trans_data storage
	if not pending_transition.is_empty():
		trans_data["transitions"].append(pending_transition)
	pending_transition = transition
	
func _on_game_reset(winner_side: int):
	# assigning rewards
	pending_transition["done"] = true
	pending_transition["reward"] = 1.0 if winner_side == side else -1.0 

func consume_transitions() -> Dictionary:
	# just return the trans_data and reset transitions array
	var old_transitions = trans_data
	var new_transitions: Dictionary = {"player_id": id, "side": side, "transitions": []}
	trans_data = new_transitions
	return old_transitions
	
func receive_weights(weights, biases):
	# sync weights between 'brains' and learners in python script
	brain.receive_weights(weights, biases)
