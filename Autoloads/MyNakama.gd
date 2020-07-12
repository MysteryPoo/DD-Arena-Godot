# This is a very messy prototype Autoload to test Nakama with a Dedicated Server
# This file won't do much of anything on its own, but I'm using it to drive 
# a dedicated server for a game already made
extends Node

enum OP {
	HOST,
	STARTGAME,
	LOBBYMESSAGE,
	REGISTER_AS_SERVER,
	END_MATCH
}

const NAKAMA_KEY := "defaultkey"
const NAKAMA_HOSTNAME := "localhost"
const NAKAMA_PORT := 7350
const NAKAMA_METHOD := "http"

onready var client : NakamaClient = Nakama.create_client(NAKAMA_KEY, NAKAMA_HOSTNAME, NAKAMA_PORT, NAKAMA_METHOD)
onready var socket : NakamaSocket = Nakama.create_socket_from(client)

var session : NakamaSession

var myName : String
var myMatchId : String
var myTicket : NakamaRTAPI.MatchmakerTicket

var myAccount : NakamaAPI.ApiAccount

var connected_opponents = {}

signal authenticated(error)
signal accountInfo

func _ready():
	socket.connect("received_match_presence", self, "_on_match_presence")
	socket.connect("connected", self, "_on_socket_connected")
	socket.connect("closed", self, "_on_socket_closed")
	socket.connect("received_error", self, "_on_socket_error")
	socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	var isServer = false
	var isMatchmaking = false
	# Refer to the containerapi.lua module as to how this ENV appears
	if OS.has_environment("SERVER"):
		if OS.get_environment("SERVER") == "true":
			isServer = true
	if OS.has_environment("NOMATCHMAKING"):
		if OS.get_environment("NOMATCHMAKING") == "0":
			isMatchmaking = true
			
	if isServer:
		if isMatchmaking:
			_setupMatchmaking()
		get_tree().change_scene("res://scenes/server.tscn")

func _setupMatchmaking():
	var email = "gameserver@example.com"
	var password = "someultramegasecretpassword"
	
	global.EXTPORT = int(OS.get_environment("EXTPORT"))
	global.MATCH_ID = OS.get_environment("MATCHID")
	
	session = yield(client.authenticate_email_async(email, password, null, true), "completed")
	var account = yield(client.get_account_async(session), "completed")
	
	var connectionAttempt: NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	if connectionAttempt.is_exception():
		print("An error occured: %s" % connectionAttempt)
		return
		
	var joined_match = yield(socket.join_match_async(global.MATCH_ID), "completed")
	if joined_match.is_exception():
		print("An error occured: %s" % joined_match)
		return
	
	socket.send_match_state_async(global.MATCH_ID, OP.REGISTER_AS_SERVER, OS.get_environment("PASSWORD"))
	


func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		connected_opponents[p.user_id] = p
	for p in p_presence.leaves:
		connected_opponents.erase(p.user_id)
	print("Connected opponents: %s" % [connected_opponents])
	
func _on_socket_connected():
	pass

func _on_socket_closed():
	pass

func _on_socket_error(error):
	print(error)
	
func _on_matchmaker_matched():
	pass

func Authenticate(email, password, create):
	session = yield(client.authenticate_email_async(email, password, null, create), "completed")
	if session.is_exception():
		emit_signal("authenticated", {
			Message = session.get_exception().message,
			Code = session.get_exception().status_code
		})
		print(session.to_string())
	else:
		emit_signal("authenticated", {
			Message = "",
			Code = 0
		})

func GetAccount():
	var account = yield(client.get_account_async(session), "completed")
	if account.is_exception():
		print(account.to_string())
		return
	myAccount = account
	emit_signal("accountInfo")

func CreateMatch():
	var query = "*"
	var min_count = 2
	var max_count = 4
	var string_properties = { "user_id": myAccount.user.id }
	var numeric_properties = { "rank": 8 }
	var matchmaker_ticket : NakamaRTAPI.MatchmakerTicket = yield(
		socket.add_matchmaker_async(query, min_count, max_count, string_properties, numeric_properties),
		"completed"
	)
	if matchmaker_ticket.is_exception():
		print("An error occured: %s" % matchmaker_ticket)
		return
	print("Got ticket: %s" % [matchmaker_ticket])
	myTicket = matchmaker_ticket
#	var created_match : NakamaAsyncResult = yield(client.rpc_async(session, "create_match_rpc"), "completed")
#	if created_match.is_exception():
#		print("An error occured: %s" % created_match)
#		return
#	var matchInfo = JSON.parse(created_match.payload).result
#
#	var match_id = matchInfo.MatchId
#	print(match_id)
#	var joined_match = yield(socket.join_match_async(match_id), "completed")
#	if joined_match.is_exception():
#		print("An error occured: %s" % joined_match)
#		return
#	myMatchId = match_id
#	for presence in joined_match.presences:
#		print("User id %s name %s'." % [presence.user_id, presence.username])

func ConnectSocket():
	if not socket.is_connected_to_host():
		if not socket.is_connecting_to_host():
			var connectionAttempt: NakamaAsyncResult = yield(socket.connect_async(session), "completed")
			if connectionAttempt.is_exception():
				print("An error occured: %s" % connectionAttempt)
				return
		else:
			print("Still attempting to connect to the server...")
			return
