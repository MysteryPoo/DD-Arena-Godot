extends Node

class LobbyData:
	var userArray = {}
	var isPublic = false
	var maxPlayers = 1
	var numPlayers = 0

enum MESSAGE_ID {
	Challenge,
	Handshake,
	Ping,
	MessageInfo,
	NewLobby,
	UpdateLobbyData,
	StartGame,
	JoinLobby,
	GetFriends,
	SetVisibleUsername,
	FriendRequest,
	GetMessages,
	SetMessage,
	UserSearch,
	LobbyPlayer,
	GetDashboard,
	GetNextBattleReport,
	GetPublicPlayerInfo,
	GetAvatarList,
	PurchaseAvatarById,
	SetAvatar,
	GetNextAward,
	GetDiceList,
	PurchaseDiceById,
	SetDice,
	INVALID,
}

var _accountInfo = {
	"id" : "0",
	"username" : "",
	"password" : "abcdefg",
	"device_uuid" : "0",
	"version" : 0,
	"lastLogin" : ""
}

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var client := StreamPeerTCP.new()
onready var lobbyData = LobbyData.new()

const accountFilename := "user://acount.info"

signal NewNameRequired
signal LoginSuccess
signal LobbyData(lobbyData, myReadyStatus)
signal StartGame(ip, port, token)

# Called when the node enters the scene tree for the first time.
func _ready():
	client.connect_to_host("dda.dragonringstudio.com", 40001)
	#client.connect_to_host("dda-2.dragonringstudio.com", 40001)
	#client.connect_to_host("localhost", 40001)
	_loadAccount()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var bytes := client.get_available_bytes()
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
				MESSAGE_ID.UpdateLobbyData:
					_handleLobbyData(m)
				MESSAGE_ID.LobbyPlayer:
					_handleLobbyPlayer(m)
				MESSAGE_ID.StartGame:
					_handleStartGame(m)
				_:
					print("Unknown message id: %s" % m.messageId)
			
		
func _handleChallenge(message):
	var handshake = {
		"messageId" : MESSAGE_ID.Handshake,
		"id" : _accountInfo.id,
		"device_uuid" : _accountInfo.device_uuid,
		"password" : _accountInfo.password,
		"version" : _accountInfo.version
	}
	print(JSON.print(handshake))
	client.put_utf8_string(JSON.print(handshake))
	
func _handleHandshake(message):
	if message.id == "0" && message.device_uuid == "0" && message.lastLogin == "0":
		print("Error received during handshake : %s" % message.username)
		if message.username.to_lower() == "account does not exist.":
			_accountInfo.id = "0"
			_accountInfo.username = ""
	else:
		_accountInfo.id = message.id
		_accountInfo.device_uuid = message.device_uuid
		_accountInfo.username = message.username
		_accountInfo.lastLogin = message.lastLogin
	_saveAccount()
	var testNewUser = message.username.left(7)
	if testNewUser.to_lower() == "newuser":
		print("Emitting signal: NewNameRequired")
		emit_signal("NewNameRequired")
	else:
		emit_signal("LoginSuccess")

func _handleLobbyData(message):
	lobbyData.maxPlayers = message.maxClients
	lobbyData.numPlayers = message.numClients
	lobbyData.isPublic = message.isPublic
	emit_signal("LobbyData", lobbyData, -1)

func _handleLobbyPlayer(message):
	var player = {
		"id" : message.id,
		"isReady" : message.isReady
	}
	lobbyData.userArray[message.clientListIndex] = player
	var myReadyStatus = -1
	if message.id == _accountInfo.id:
		if message.isReady:
			myReadyStatus = 1
		else:
			myReadyStatus = 0
	emit_signal("LobbyData", lobbyData, myReadyStatus)

func _handleStartGame(message):
	#emit_signal("StartGame", message.ip, int(message.port), int(message.token))
	emit_signal("StartGame", message.ip, int(message.port), 0)

func _loadAccount():
	var file := File.new();
	if file.file_exists(accountFilename):
		file.open(accountFilename, File.READ)
		var loadedAccount = JSON.parse(file.get_line()).result
		_accountInfo.id = loadedAccount.id
		_accountInfo.password = loadedAccount.password
		_accountInfo.device_uuid = loadedAccount.device_uuid
		_accountInfo.lastLogin = loadedAccount.lastLogin
		file.close()

func _saveAccount():
	var file := File.new()
	file.open(accountFilename, File.WRITE)
	file.seek(0)
	file.store_string(JSON.print(_accountInfo))
	
func ChangeName(newName):
	var message = {
		"messageId" : MESSAGE_ID.SetVisibleUsername,
		"username" : newName
	}
	client.put_utf8_string(JSON.print(message))

func CreateLobby():
	var message = {
		"messageId" : MESSAGE_ID.NewLobby,
		"isPublic" : lobbyData.isPublic,
		"maxPlayers" : lobbyData.maxPlayers
	}
	client.put_utf8_string(JSON.print(message))

func LeaveLobby():
	var message = {
		"messageId" : MESSAGE_ID.LobbyPlayer,
		"isReady" : false,
		"requestingToLeaveLobby" : true
	}
	client.put_utf8_string(JSON.print(message))

func UpdateLobby(isPublic, maxPlayers):
	var message = {
		"messageId" : MESSAGE_ID.UpdateLobbyData,
		"isPublic" : isPublic,
		"maxClients" : maxPlayers
	}
	client.put_utf8_string(JSON.print(message))

func SetReady(ready):
	var message = {
		"messageId" : MESSAGE_ID.LobbyPlayer,
		"isReady" : ready,
		"requestingToLeaveLobby" : false
	}
	client.put_utf8_string(JSON.print(message))

func StartGame():
	var message = {
		"messageId" : MESSAGE_ID.StartGame
	}
	client.put_utf8_string(JSON.print(message))
