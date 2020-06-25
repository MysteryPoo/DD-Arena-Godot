# This is a very messy prototype Autoload to test Nakama with a Dedicated Server
# This file won't do much of anything on its own, but I'm using it to drive 
# a dedicated server for a game already made
extends Node

var client : NakamaClient
var socket : NakamaSocket

var myName : String

var connected_opponents = {}

func _ready():
	client = Nakama.create_client("defaultkey", "127.0.0.1", 7350, "http")
	var isServer = false
	# Refer to the containerapi.lua module as to how this ENV appears
	if OS.has_environment("SERVER"):
		if OS.get_environment("SERVER") == "true":
			isServer = true
			
	if isServer:
		var email = "gameserver@example.com"
		var password = "someultramegasecretpassword"
		
		global.EXTPORT = int(OS.get_environment("EXTPORT"))
		global.MATCH_ID = OS.get_environment("MATCHID")
		
		var session = yield(client.authenticate_email_async(email, password, null, false), "completed")
		var account = yield(client.get_account_async(session), "completed")
		
		socket = Nakama.create_socket("nakama")
		socket.connect("received_match_presence", self, "_on_match_presence")
		
		var connectionAttempt: NakamaAsyncResult = yield(socket.connect_async(session), "completed")
		if connectionAttempt.is_exception():
			print("An error occured: %s" % connectionAttempt)
			return
			
		var joined_match = yield(socket.join_match_async(global.MATCH_ID, global.EXTPORT), "completed")
		if joined_match.is_exception():
			print("An error occured: %s" % joined_match)
			return
		for presence in joined_match.presences:
			print("User id %s name %s'." % [presence.user_id, presence.username])
		
	else:
		var email = "hello@example.com"
		var password = "somesupersecretpassword"

		var session = yield(client.authenticate_email_async(email, password, null, false), "completed")
		var account = yield(client.get_account_async(session), "completed")
		print("User id: %s" % account.user.id)
		myName = account.user.username
		#print("User username: '%s'" % account.user.username)
		#print("Account virtual wallet: %s" % str(account.wallet))
		
		
		socket = Nakama.create_socket()
		socket.connect("received_match_presence", self, "_on_match_presence")
		var connectionAttempt: NakamaAsyncResult = yield(socket.connect_async(session), "completed")
		if connectionAttempt.is_exception():
			print("An error occured: %s" % connectionAttempt)
			return
		
		var created_match : NakamaAsyncResult = yield(client.rpc_async(session, "create_match_rpc"), "completed")
		if created_match.is_exception():
			print("An error occured: %s" % created_match)
			return
		
		var matchInfo = JSON.parse(created_match.payload).result
		print("New match with id %s.", matchInfo.MatchId)
		
		var match_id = matchInfo.MatchId
		var joined_match = yield(socket.join_match_async(match_id), "completed")
		if joined_match.is_exception():
			print("An error occured: %s" % joined_match)
			return
		for presence in joined_match.presences:
			print("User id %s name %s'." % [presence.user_id, presence.username])
		
		print(matchInfo)
		global.EXTPORT = int(matchInfo.Port)
		global.MATCH_ID = matchInfo.MatchId
			
		get_tree().change_scene("res://scenes/client.tscn")

func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		connected_opponents[p.user_id] = p
	for p in p_presence.leaves:
		connected_opponents.erase(p.user_id)
	print("Connected opponents: %s" % [connected_opponents])
