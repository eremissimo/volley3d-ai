extends Node3D

#number of field copies
@export_range(1,20) var rows := 1
@export_range(1,20) var cols := 1
@export var row_spacing: float = 1.5
@export var col_spacing: float = 1.0
# var fields: Array[VolleyField] = []
const VolleyScene = preload("res://volley_field.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var pos: = Vector3.ZERO
	for i in cols:
		for j in rows:
			var field = VolleyScene.instantiate()
			# position of the field clone
			pos.z = i*(field.field_size[1] + col_spacing)
			pos.x = j*(field.field_size[0] + row_spacing)
			field.position = pos
			# fields.append(field)
			add_child(field)
			
func get_env_info() -> Dictionary:
	var n_fields = get_child_count()
	var fields_info: Array[Dictionary] = []
	for field in get_children():
		fields_info.append(field.get_env_info())
	var env_info := {"n_fields": n_fields, 
					 "fields_info": fields_info,
					 "state_size": VolleyField.state_size,
					 "action_size": VolleyField.action_size}
	return env_info

