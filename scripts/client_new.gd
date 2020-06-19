extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var node_player = get_node("Players/Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	node_player.SetAsActiveCamera()
	pass # Replace with function body.

func PickUpBombs(body, bombs):
	if body == node_player:
		bombs.Pickup(body)
		bombs.queue_free()
		body.AddAmmunition(bombs.GetAmmunition())
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
