extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var velocity = Vector2()
var _ammunition = 0
var _canPlayFootsteps = true

onready var sprite = get_node("AnimatedSprite")
onready var camera = get_node("Camera2D")
onready var footsteps = get_node("Footsteps")
onready var timer = get_node("Footsteps/Timer")

export (int) var speed = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector2()
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	velocity = velocity.normalized() * speed
	if velocity.y > 0:
		sprite.animation = "WalkDown"
	elif velocity.y < 0:
		sprite.animation = "WalkUp"
	else:
		if velocity.x < 0:
			sprite.animation = "WalkLR"
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.animation = "WalkLR"
			sprite.flip_h = false
		else:
			sprite.animation = "Standing"

	if sprite.animation != "Standing" && !footsteps.playing && _canPlayFootsteps:
		footsteps.play()
		_canPlayFootsteps = false
		timer.start(0.3)

func _physics_process(_delta):
	velocity = move_and_slide(velocity)

func AddAmmunition(amount):
	_ammunition += amount
	print("Ammunition: %s" % str(_ammunition))

func SetAsActiveCamera():
	camera.make_current()


func _on_Timer_timeout():
	_canPlayFootsteps = true
