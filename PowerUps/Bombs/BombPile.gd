extends Node2D

export (int) var _ammunition = 5
export (int) var _effectDelay = 10

var preload_bombpickup = preload("res://PowerUps/Bombs/BombPickup.tscn")
var sprite_array = []
var nearby_bodies = []

onready var node_world = get_node("/root/world")
onready var sprite_icon = get_node("Icon")
onready var timer_respawn = get_node("Respawn")

signal pickup_bombs(amount)

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_array.append(get_node("Bomb1"))
	sprite_array.append(get_node("Bomb2"))
	sprite_array.append(get_node("Bomb3"))
	sprite_array.append(get_node("Bomb4"))
	sprite_array.append(get_node("Bomb5"))
	sprite_icon.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for b in range(0, 5):
		if _ammunition > b:
			sprite_array[b].visible = true
		else:
			sprite_array[b].visible = false
			
	if visible && nearby_bodies.size() > 0:
		var body = nearby_bodies[0]
		Pickup(body)


func _on_Area2D_body_entered(body: Node2D):
	if body.has_method("AddAmmunition"):
		nearby_bodies.append(body)
		
func _on_Area2D_body_exited(body):
	nearby_bodies.erase(body)
	
func Pickup(targetNode):
	timer_respawn.start()
	visible = false
	targetNode.AddAmmunition(_ammunition)
	for b in range(0, _ammunition):
		var bombPickup = preload_bombpickup.instance()
		bombPickup.position = position + sprite_array[b].position
		node_world.add_child(bombPickup)
		bombPickup.SetTarget(targetNode)
		bombPickup.SetDelay(_effectDelay * b)

func _on_Respawn_timeout():
	visible = true
