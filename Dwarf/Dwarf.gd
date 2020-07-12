extends KinematicBody2D


var preload_bomb = preload("res://Bomb/Bomb.tscn")

var velocity = Vector2()
var _ammunition = 0
var _canPlayFootsteps = true
var _myBomb: Node2D = null

onready var camera = get_node("Camera2D")
onready var footsteps = get_node("Footsteps")
onready var timer = get_node("Footsteps/Timer")
onready var playback = get_node("AnimationTree").get("parameters/playback")

onready var myBody = get_node("Body")
onready var regularHead = get_node("Body/Heads/Head")
onready var smileHead = get_node("Body/Heads/Head2")

export (int) var speed = 200

func _ready():
	pass

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

	if velocity != Vector2.ZERO:
		#var new_rotation = rad2deg(position.angle_to_point(position - velocity))
		#rotation_degrees = new_rotation
		#get_node("Tween").interpolate_property(self, NodePath("rotation_degrees"), null, new_rotation, 0.5)
		look_at(position + velocity)
		playback.travel("Walking")
		if !footsteps.playing && _canPlayFootsteps:
			footsteps.play()
			_canPlayFootsteps = false
			timer.start(0.3)
	else:
		playback.travel("Idle")
	
	

func _physics_process(_delta):
	velocity = move_and_slide(velocity)

func AddAmmunition(amount):
	_ammunition += amount
	print("Ammunition: %s" % str(_ammunition))

func SetAsActiveCamera():
	camera.make_current()

func _on_Timer_timeout():
	_canPlayFootsteps = true

func _on_damage(damage):
	print("Hit by bomb for %d damage!" % damage)
	
func _on_bomb_destroyed():
	_myBomb = null
