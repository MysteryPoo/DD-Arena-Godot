extends Node2D

onready var http_request = HTTPRequest.new()

var presence = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed")
	
func LoadAvatar(url):
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var http_error = http_request.request(url)
	if http_error != OK:
		print("An error occurred in the HTTP request.")
		
func SetName(name):
	get_node("Name").text = name
	
func SetPresence(newPresence):
	presence = newPresence

func SetHost(isHost):
	get_node("Host").visible = isHost

func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Assign to the child TextureRect node
	$Sprite.texture = texture
