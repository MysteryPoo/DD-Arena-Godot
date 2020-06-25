extends KinematicBody2D


var preload_bomb = preload("res://Bomb/Bomb.tscn")

var velocity = Vector2()
var _ammunition = 0
var _canPlayFootsteps = true
var _myBomb: Node2D = null

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
	if Input.is_action_pressed("player_up"):
		velocity.y -= 1
	if Input.is_action_pressed("player_down"):
		velocity.y += 1
	if Input.is_action_pressed("player_left"):
		velocity.x -= 1
	if Input.is_action_pressed("player_right"):
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
			
	if Input.is_action_just_pressed("player_fire") && _myBomb == null && _ammunition > 0:
		_myBomb = preload_bomb.instance()
		_myBomb.connect("tree_exiting", self, "_on_bomb_destroyed")
		get_node("/root/world").add_child(_myBomb)
		_ammunition -= 1
		
	if Input.is_action_just_released("player_fire") && _myBomb != null:
		var direction = get_global_mouse_position() - position
		_myBomb.Release(direction)
		_myBomb.disconnect("tree_exiting", self, "_on_bomb_destroyed")
		_myBomb = null
		
	if _myBomb != null:
		_myBomb.position = position

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

func _damage(damage):
	print("Hit by bomb for %d damage!" % damage)
	
func _on_bomb_destroyed():
	_myBomb = null
