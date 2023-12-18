extends Node3D

@export_range(1.0, 10.0, 0.5) var speedup = 1.0

func _ready():
	Engine.time_scale = speedup
	Engine.physics_ticks_per_second = int(speedup * 60)

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit(0)
