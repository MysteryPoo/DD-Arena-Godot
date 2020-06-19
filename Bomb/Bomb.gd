extends KinematicBody2D


export (int) var _fuse = 3

onready var animation = get_node("AnimationPlayer")
onready var warning = get_node("Warning")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_fuse -= delta
	if animation.current_animation != "Explode" && _fuse < 1:
		animation.play("Explode")
		warning.visible = true
	if _fuse <= 0:
		queue_free()
