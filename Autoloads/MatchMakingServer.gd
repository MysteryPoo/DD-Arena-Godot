extends Node

enum MESSAGE_ID {
	Challenge,
	Handshake,
	Ping,
	NotifyState,
	BattleReport,
	INVALID
}
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const version = 0

var client := StreamPeerTCP.new()
var settings = {
	"auth_ip" : "127.0.0.1",
	"auth_port" : 40001,
	"port" : 40002,
	"host" : "",
	"password" : "",
	"playerCount" : 1,
	"botCount" : 0,
	"noMatchmaking" : true
}
var auth_ip = "dda.dragonringstudio.com"
var auth_port = 40002
var port = 40003
var host = ""
var password = ""
var playerCount = 1
var botCount = 0
var noMatchmaking = false

var _connected = false



# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_environment("AUTHIP"):
		auth_ip = OS.get_environment("AUTHIP")
	if OS.has_environment("AUTHPORT"):
		auth_port = int(OS.get_environment("AUTHPORT"))
	if OS.has_environment("PORT"):
		port = int(OS.get_environment("PORT"))
	if OS.has_environment("HOST"):
		host = OS.get_environment("HOST")
	if OS.has_environment("PASSWORD"):
		password = OS.get_environment("PASSWORD")
	if OS.has_environment("PLAYERCOUNT"):
		playerCount = int(OS.get_environment("PLAYERCOUNT"))
	if OS.has_environment("BOTCOUNT"):
		botCount = int(OS.get_environment("BOTCOUNT"))
	if OS.has_environment("NOMATCHMAKING"):
		var env = OS.get_environment("NOMATCHMAKING")
		noMatchmaking = true if env == "true" else false
	print("auth_ip: %s" % auth_ip)
	print("auth_port: %s" % str(auth_port))
	print("port: %s" % str(port))
	print("host: %s" % host)
	print("password: %s" % password)
	print("playerCount: %s" % str(playerCount))
	print("botCount: %s" % str(botCount))
	print("noMatchmaking: %s" % ("true" if noMatchmaking else "false"))

func ConnectToMatchmaking():
	if noMatchmaking == false:
		if client.connect_to_host(auth_ip, auth_port) != OK:
			print("Unable to connect to matchmaking server...")
			get_tree().quit()
		else:
			_connected = true
			print("Connected to matchmaking server...")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var bytes = 0
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		bytes = client.get_available_bytes()
	elif _connected:
		print("Not connected to Matchmaking Server")
		_connected = false
	if bytes > 0:
		var data := client.get_string(bytes)
		data = "[" + data.replace("}{", "},{") + "]"
		var message = JSON.parse(data).result
		print(message)
		assert(message.size() > 0)
		for m in message:
			match m.messageId as int:
				MESSAGE_ID.Challenge:
					_handleChallenge(m)
				MESSAGE_ID.Handshake:
					_handleHandshake(m)
				_:
					print("Unknown message id: %s" % m.messageId)

func _handleChallenge(message):
	var handshake = {
		"messageId" : MESSAGE_ID.Handshake,
		"gameVersion" : version,
		"gameServerPassword" : password,
		"playerIdList" : [host]
	}
	client.put_utf8_string(JSON.print(handshake))

func _handleHandshake(message):
	pass
