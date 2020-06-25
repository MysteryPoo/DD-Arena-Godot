extends Node2D

var preload_bomb = preload("res://Bomb/Bomb.tscn")

onready var node_player = get_node("Players/Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	node_player.SetAsActiveCamera()
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/149.png")
	if http_error != OK:
		print("An error occurred in the HTTP request.")
	pass # Replace with function body.

func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Assign to the child TextureRect node
	$Sprite.texture = texture

func CreateBomb():
	return preload_bomb.instance()
