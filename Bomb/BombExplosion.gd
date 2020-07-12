extends Node2D

onready var particle = get_node("Particles2D")

var _fired = false

func _ready():
	_fired = true
	print("Hello")

func _process(_delta):
	if _fired && particle.emitting == false:
		print("Bye")
		queue_free()
