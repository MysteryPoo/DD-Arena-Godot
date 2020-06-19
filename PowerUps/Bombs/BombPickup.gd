extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var _target_node = null
var _delay = 0

onready var node_animation = get_node("AnimationPlayer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if _target_node != null && _delay <= 0:
		if node_animation.current_animation != "Shrink":
			node_animation.play("Shrink")
		position = lerp(position, _target_node.position, 0.1)
		var distance = _target_node.position.distance_to(position)
		if distance < 16:
			queue_free()
	else:
		_delay -= 1

func SetTarget(node):
	_target_node = node

func SetDelay(delay):
	_delay = delay
