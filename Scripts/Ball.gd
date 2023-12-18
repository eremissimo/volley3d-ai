class_name Ball extends RigidBody3D


#side=1 if left player wins, side=-1 for right:
signal ball_on_ground(winner_side: int)
signal more_than_three_touches(winner_side: int)


var first_collision: bool = true
var touch_counter: int = 0
var prev_touch_side: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", _on_ball_collision)
	reset(1)


# side = 1 for left player, side = -1 for right player
func reset(side: int):
	# gravity_scale = 0.0
	position = Vector3(-side*5.0, 3.5, 0.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	first_collision = true
	gravity_scale = 0.0
	touch_counter = 0
	prev_touch_side = 0


func _on_ball_collision(body):
	# switching on the gravity on the first collision
	if first_collision:
		first_collision = false
		gravity_scale = 1.0
	# handling ground collision
	var collision_side := -signf(self.position.x) as int	# left 1, right -1
	if body.is_in_group("ground"):
		handle_ball_on_ground_reset(collision_side)
	# handling 3 touches rule
	# (this could cause problems with learning)
	elif body.is_in_group("player"):
		if collision_side == prev_touch_side:
			touch_counter += 1
			if touch_counter > 3:
				# reusing ball_on_ground signal (that's lame tbh)
				handle_3touches_reset(collision_side)
		else:
			touch_counter = 1
			prev_touch_side = collision_side


func handle_ball_on_ground_reset(collision_side: int):
	# assuming collision_side = -1 when collision happened on the left side
	# and 1 on the right side
	ball_on_ground.emit(-collision_side)
	reset(-collision_side)
	
func handle_3touches_reset(collision_side: int):
	more_than_three_touches.emit(-collision_side)
	reset(-collision_side)
