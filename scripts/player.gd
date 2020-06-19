extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var label_name = get_node("label_name")
onready var rect_isReady = get_node("rect_isReady")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func SetName(name):
	self.name = name
	label_name.text = name
	
func SetReady(ready):
	if ready:
		rect_isReady.color = Color(0, 100, 0)
	else:
		rect_isReady.color = Color(100, 0, 0)
