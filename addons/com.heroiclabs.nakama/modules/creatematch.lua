-- This module merely encapsulates the match creation process for creating an authoritative match.
-- Notice the call to containerapi. I think eventually this will move to inside the match itself
-- and we can use the matchmaker create hook to create the "dda" module instance instead of this RPC.
-- My prototype doesn't actually have matchmaking, yet.

local nk = require("nakama")

local function create_match(context, payload)
	nk.logger_info("RPC called: create_match_rpc")
	local modulename = "dda"
	local setupstate = { initialstate = payload }
	local matchid = nk.match_create(modulename, setupstate)
	
	return nk.json_encode({
		["MatchId"] = matchid
	})
	
end

nk.register_rpc(create_match, "create_match_rpc")
