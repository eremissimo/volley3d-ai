class_name Controller extends RefCounted
# a base class for ManualController and AIController

var side: int

func _init(side_: int):
	self.side = side_

func jumped():
	assert(false, "Implement me")


func input_direction():
	assert(false, "Implement me")


