extends CanvasLayer

var lobby_users = {}
var match_id = ""
var host_id = ""

onready var preload_lobbyUser = preload("res://scenes/Lobby/LobbyUser/lobbyUser.tscn")
onready var grid_LobbyUsers = get_node("ui/grid_LobbyUsers")

func _ready():
	MyNakama.socket.connect("received_match_presence", self, "_on_match_presence")
	MyNakama.socket.connect("closed", self, "_on_socket_closed")
	MyNakama.socket.connect("connected", self, "_on_socket_connected")
	MyNakama.socket.connect("received_match_state", self, "_on_received_match_state")
	MyNakama.ConnectSocket()

func _process(_delta):
	pass
	
func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		var lobbyUser = preload_lobbyUser.instance()
		grid_LobbyUsers.add_child(lobbyUser)
		lobbyUser.SetName(p.username)
		lobbyUser.SetPresence(p)
		var ids = ["userid1", "userid2"]
		var usernames = ["username1", "username2"]
		var facebook_ids = ["facebookid1"]
		var result : NakamaAPI.ApiUsers = yield(MyNakama.client.get_users_async(MyNakama.session, [p.user_id]), "completed")
		if result.is_exception():
			print("An error occured: %s" % result)
			continue
		for u in result.users:
			print("User id '%s' username '%s'" % [u.id, u.username])
		lobbyUser.LoadAvatar(result.users[0].avatar_url)
		lobby_users[p.user_id] = lobbyUser
	for p in p_presence.leaves:
		lobby_users[p.user_id].queue_free()
		lobby_users.erase(p.user_id)
	print("Connected opponents: %s" % [lobby_users])

func _on_socket_closed():
	print("Socket closed...")
	get_tree().change_scene("res://scenes/login.tscn")

func _on_socket_connected():
	MyNakama.CreateMatch()
	pass

func _on_received_match_state(p_match_state):
	if p_match_state.op_code == MyNakama.OP.HOST:
		if host_id != p_match_state.data:
			print("Host has changed to: %s" % p_match_state.data)
			_setHost(p_match_state.data)
	elif p_match_state.op_code == MyNakama.OP.STARTGAME:
		var message = JSON.parse(p_match_state.data).result
		global.EXTPORT = int(message.Port)
		get_tree().change_scene("res://scenes/client.tscn")
	elif p_match_state.op_code == MyNakama.OP.LOBBYMESSAGE:
		get_node("ui/Label_LobbyMessage").text = p_match_state.data
	else:
		pass

func _on_lobby_tree_exiting():
	MyNakama.socket.disconnect("received_match_presence", self, "_on_match_presence")
	MyNakama.socket.disconnect("closed", self, "_on_socket_closed")
	MyNakama.socket.disconnect("connected", self, "_on_socket_connected")
	MyNakama.socket.disconnect("received_match_state", self, "_on_received_match_state")

func _setHost(new_host):
	host_id = new_host
	if new_host == MyNakama.session.user_id:
		get_node("ui/Button_Start").visible = true
	for u_id in lobby_users:
		var user = lobby_users[u_id]
		if user.presence.user_id == new_host:
			user.SetHost(true)
		else:
			user.SetHost(false)
	print("Setting host to: %s" % new_host)


func _on_Button_Start_pressed():
	print("Starting game!")
	MyNakama.socket.send_match_state_async(MyNakama.myMatchId, MyNakama.OP.STARTGAME, "Nothing")
