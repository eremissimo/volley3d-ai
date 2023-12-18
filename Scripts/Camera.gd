class_name CustomCamera extends Node3D

@export_group("Camera Properties")
@export var speed: float = 5.0
@export var altitude: float = 12.0
@export_range(0, 1, 0.1) var mouse_sensitivity := 0.1

@onready var cam = $"Camera3D"

func _ready():
	position.y = altitude
	# TODO: wtf is this?
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += get_3d_direction() * speed * delta


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		cam.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		self.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		cam.rotation.x = clampf(cam.rotation.x, -1.4, 1.4)


func get_3d_direction() -> Vector3:
	var input_dir = Input.get_vector("cam_left", "cam_right", "cam_forward", "cam_backward")
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
