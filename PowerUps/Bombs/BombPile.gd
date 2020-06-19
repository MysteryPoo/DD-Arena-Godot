extends Node2D

export (int) var _ammunition = 5
export (int) var _effectDelay = 10

var preload_bombpickup = preload("res://PowerUps/Bombs/BombPickup.tscn")
var sprite_array = []

onready var node_world = get_node("/root/world")
onready var sprite_icon = get_node("Icon")

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


func _on_Area2D_body_entered(body):
	node_world.PickUpBombs(body, self)
	
func Pickup(targetNode):
	print(position)
	for b in range(0, _ammunition):
		var bombPickup = preload_bombpickup.instance()
		print(sprite_array[b].position)
		bombPickup.position = position + sprite_array[b].position
		node_world.add_child(bombPickup)
		bombPickup.SetTarget(targetNode)
		bombPickup.SetDelay(_effectDelay * b)

func GetAmmunition():
	return _ammunition
