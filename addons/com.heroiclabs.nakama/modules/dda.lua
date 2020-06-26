-- This is basically the standard example provided in Nakama docs for a minimalist repeater server
-- It's being used as a stand-in for now, but will evolve logic to handle "Lobby" type stuff.
-- Unless I missed it, Nakama doesn't have lobbies (the state where you're matched up but not playing anything)
-- According to their docs, this module space is intended to handle the server-side game logic
-- This is not ideal for me, as I want my game engine to handle that on a dedicated server app. So,
-- I can instead use this space as a sort of lobby space to connect a dedicated server for match participants
-- to connect and group together (like friends) prior to a real matchmaking. These are all still thoughts;
-- I have yet to design anything for that capability. 
local nk = require("nakama")

local M = {}

local OP_HOST = 0
local OP_STARTGAME = 1
local OP_LOBBYMESSAGE = 2
local OP_REGISTER_AS_SERVER = 3

function M.match_init(context, setupstate)
	local gamestate = {
		presences = {},
		host = nil,
		server_requested = false,
		server = nil,
		server_password = "testing",
		server_port = 0
	}
	local tickrate = 1 -- per sec
	local label = "dda"
	nk.logger_info(string.format("Match: %s : Initializing...", context.match_id))
	return gamestate, tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	local acceptuser = true
	if (state.host == nil) then
		state.host = presence.user_id
	end
	return state, acceptuser
end

function M.match_join(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = presence
	end
	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, presence in ipairs(presences) do
		state.presences[presence.session_id] = nil
	end
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	-- for _, presence in pairs(state.presences) do
		-- nk.logger_info(string.format("Presence %s named %s", presence.user_id, presence.username))
	-- end
	-- for _, message in ipairs(messages) do
		-- nk.logger_info(string.format("Received OpCode: %d, Data: %s from %s", message.op_code, message.data, message.sender.username))
		-- if (message.sender.user_id == state.host) then nk.logger_info("Message is from host.") end
		-- local decoded = nk.json_decode(message.data)
		-- for k, v in pairs(decoded) do
			-- nk.logger_info(string.format("Message key %s contains value %s", k, v))
			
		-- end
		-- -- PONG message back to sender
		-- dispatcher.broadcast_message(1, message.data)
	-- end
	--dispatcher.broadcast_message(OP_HOST, state.host)
	for _, message in ipairs(messages) do
		nk.logger_info(string.format("Received OpCode: %d, Data: %s from %s", message.op_code, message.data, message.sender.username))
		if message.op_code == OP_STARTGAME then
			if state.host == message.sender.user_id and false == state.server_requested then
				state.server_requested = true
				local success, port = request_gameserver(context, state)
				if (not success) then
					nk.logger_error(port)
					dispatcher.broadcast_message(OP_LOBBYMESSAGE, "Unable to create a server...")
					state.server_requested = false
				else
					-- local message = nk.json_encode({
						-- ["Port"] = port
					-- })
					state.server_port = port
					dispatcher.broadcast_message(OP_LOBBYMESSAGE, "Server requested...")
				end
			else
				nk.logger_warn("Non-host sent a host-only message")
			end
		elseif message.op_code == OP_REGISTER_AS_SERVER then
			if state.server_requested and state.server_password == message.data then
				state.server = message.sender.user_id
				dispatcher.broadcast_message(OP_STARTGAME, nk.json_encode({
					["Port"] = state.server_port
				}))
			else
				nk.logger_warn("A server registration request resulted in a failure.")
				state.server_requested = false
			end
		end
	end
	
	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
	local message = "Server shutting down in " .. grace_seconds .. " seconds"
	dispatcher.broadcast_message(OP_LOBBYMESSAGE, message)
	return nil
end

local function request_gameserver(context, state)
	local success, port = pcall(containerapi.RequestGameServer, context.match_id, state.server_password)
	if (not success) then
		error(port)
	else
		return port
	end
end

return M
