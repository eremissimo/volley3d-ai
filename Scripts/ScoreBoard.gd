class_name ScoreBoard3D extends Node3D


@export var max_score: int = 99
var score: Array[int] = [0, 0]
@onready var disp = $"Display"

# Called when the node enters the scene tree for the first time.
func _ready():
	var ball: Ball = $"../Ball"
	ball.connect("ball_on_ground", increment_winner_score)
	ball.connect("more_than_three_touches", increment_winner_score)


func increment_winner_score(winner_side: int):
	# assuming side = 1 for left player, side = -1 for right player
	var idx = (-winner_side + 1) / 2
	if score[idx] == max_score:
		score.fill(0)	# reset score
	score[idx] += 1
	display()
	
	
func display():
	disp.text = "%02d:%02d" % score
 
	
	
