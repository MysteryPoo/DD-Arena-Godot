# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# Populate the login form and handle callbacks
# on buttons.
#
# *************************************************
extends CanvasLayer

onready var input_color = $ui/grid/input_color
onready var label_player = get_node("ui/grid/label_player")
onready var input_player =$ui/grid/text_player
onready var button_changeName = get_node("ui/grid/text_player/button_changeName")
onready var input_hostname = $ui/grid/text_hostname
onready var grid = get_node("ui/grid")
onready var panel_LobbyData = get_node("ui/LobbyData")
onready var button_decPlayers = get_node("ui/LobbyData/button_decPlayers")
onready var label_MaxPlayers = get_node("ui/LobbyData/label_MaxPlayers")
onready var button_incPlayers = get_node("ui/LobbyData/button_incPlayers")
onready var button_isPublic = get_node("ui/LobbyData/button_isPublic")
onready var player_instance = preload("res://scenes/player.tscn")
onready var grid_LobbyPlayers = get_node("ui/grid_LobbyPlayers")
onready var button_isReady = get_node("ui/LobbyData/button_isReady")
onready var label_error = get_node("ui/LobbyData/label_error")
onready var button_start = get_node("ui/grid/button_login")

var playerData = {}

func _ready():
	# Adding four spaceship colors
	input_color.add_item("Blue")
	input_color.add_item("Red")
	input_color.add_item("Green")
	input_color.add_item("Yellow")
	
	# Set default hostname
	input_hostname.text = global.DEFAULT_HOSTNAME
	
	# Hide Player Name
	label_player.visible = false
	input_player.visible = false
	button_changeName.visible = false
	
	MatchMakingClient.connect("NewNameRequired", self, "_newNameRequired")
	MatchMakingClient.connect("LoginSuccess", self, "_on_loginSuccess")
	MatchMakingClient.connect("LobbyData", self, "_on_lobbyData")
	MatchMakingClient.connect("StartGame", self, "_on_startGame")

# Callback function for "Start!" button
func _on_button_login_pressed():
	MatchMakingClient.StartGame()

# Callback function for "Start Server" button
func _on_button_start_server_pressed():
	# Change to server scene
	if get_tree().change_scene("res://scenes/server.tscn") != OK:
		print("Unable to load server scene!")

func _newNameRequired():
	print("New Name Required")
	grid.visible = true
	label_player.visible = true
	input_player.visible = true
	button_changeName.visible = true

func _on_button_changeName_pressed():
	MatchMakingClient.ChangeName(input_player.text)
	button_changeName.visible = false
	input_player.editable = false

func _on_loginSuccess():
	MatchMakingClient.CreateLobby()

func _on_lobbyData(lobbyData, myReadyStatus):
	panel_LobbyData.visible = true
	_setLobbyControls(false)
	label_MaxPlayers.text = str(lobbyData.maxPlayers)
	button_isPublic.pressed = lobbyData.isPublic
	for p in lobbyData.userArray:
		var player = lobbyData.userArray.get(p)
		if not playerData.has(player.id):
			playerData[player.id] = player_instance.instance()
			grid_LobbyPlayers.add_child(playerData[player.id])
		playerData.get(player.id).SetName(player.id)
		playerData.get(player.id).SetReady(player.isReady)
	if myReadyStatus == 0:
		button_isReady.pressed = false
	elif myReadyStatus == 1:
		button_isReady.pressed = true

func _on_button_incPlayers_pressed():
	var isPublic = button_isPublic.pressed
	var maxPlayers = MatchMakingClient.lobbyData.maxPlayers + 1
	MatchMakingClient.UpdateLobby(isPublic, maxPlayers)
	_setLobbyControls(true)

func _on_button_isPublic_pressed():
	var isPublic = button_isPublic.pressed
	var maxPlayers = MatchMakingClient.lobbyData.maxPlayers
	MatchMakingClient.UpdateLobby(isPublic, maxPlayers)
	_setLobbyControls(true)

func _on_button_decPlayers_pressed():
	var isPublic = button_isPublic.pressed
	var maxPlayers = max(1, MatchMakingClient.lobbyData.maxPlayers - 1)
	MatchMakingClient.UpdateLobby(isPublic, maxPlayers)
	_setLobbyControls(true)

func _setLobbyControls(disabled):
	button_start.disabled = disabled
	button_isPublic.disabled = disabled
	button_incPlayers.disabled = disabled
	button_decPlayers.disabled = disabled


func _on_button_isReady_pressed():
	MatchMakingClient.SetReady(button_isReady.pressed)
	_setLobbyControls(true)

func _on_startGame(ip, port, token):
	if port == 0 && token == 0:
		label_error.text = ip
	else:
		global.cfg_server_ip = ip
		global.SERVER_PORT = port
		if get_tree().change_scene("res://scenes/client.tscn") != OK:
			print("Unable to load server scene!")
		#Start the Game
		#Start the Game
