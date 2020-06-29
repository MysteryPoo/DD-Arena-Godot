-- This module merely encapsulates the match creation process for creating an authoritative match.
-- Notice the call to containerapi. I think eventually this will move to inside the match itself
-- and we can use the matchmaker create hook to create the "dda" module instance instead of this RPC.
-- My prototype doesn't actually have matchmaking, yet.

local nk = require("nakama")
local containerapi = require("containerapi")

local function create_match(context, payload)
	local modulename = "dda"
	local setupstate = { initialstate = payload }
	local matchid = nk.match_create(modulename, setupstate)
	
	local success, port = pcall(containerapi.RequestGameServer, matchid)
	if (not success) then
		error(port)
	else
		-- Send notification of some kind
		return nk.json_encode({
			["MatchId"] = matchid,
			["Port"] = port
		})
	end
	
end

nk.register_rpc(create_match, "create_match_rpc")
