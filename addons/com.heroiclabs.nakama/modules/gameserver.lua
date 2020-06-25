local nk = require("nakama")
local containerapi = require("containerapi")

local function get_containers(_, payload)
	
	local success, result = pcall(containerapi.GetServerPool)
	if (not success) then
		error("Unable to get list of containers")
	else
		return nk.json_encode(result)
	end
end

nk.register_rpc(get_containers, "get_containers")


local function launch_gameserver(_, payload)
	local success, result = pcall(containerapi.CreateContainer, 40100)
	if (not success) then
		error("Could not create container")
	else
		return nk.json_encode(result)
	end
end

nk.register_rpc(launch_gameserver, "launch_gameserver")

local function free_port(_, payload)
	local success, result = pcall(containerapi.GetFreePort)
	if (not success) then
		error("Failure finding a free port")
	else
		return nk.json_encode({
			["port"] = result
		})
	end
end

nk.register_rpc(free_port, "free_port")

local function request_server(_, payload)
	local success, result = pcall(containerapi.RequestGameServer)
	if (not success) then
		error(result)
	else
		return nk.json_encode({
			["port"] = result
		})
	end
end

nk.register_rpc(request_server, "request_server")
