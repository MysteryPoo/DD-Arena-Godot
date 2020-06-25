----------------------------------------------------------------------------
-- * "THE BEER-WARE LICENSE" (Revision 42):
-- * MysteryPoo wrote this file.  As long as you retain this notice you
-- * can do whatever you want with this stuff. If we meet some day, and you think
-- * this stuff is worth it, you can buy me a beer in return.   MysteryPoo
------------------------------------------------------------------------------


-- This module contains the API to interact with the Docker Engine API facilitating the 
-- dynamic creation of Game Server containers within a restricted port range
-- Obviously needs work

local nk = require("nakama")

local M = {}

-- Setting up some constants (Preferably I'd like to inject these through an external config at runtime, somehow
local DOCKER_HOSTNAME = "host.docker.internal"
local DOCKER_PORT = 2375

local nakamaIp = "nakama"
local nakamaPort = 7350

local minPort = 40100
local maxPort = 40199

-- Helper function to encode a full URL string based on parameters
-- returns a URL endpoint
local function GetUrl(path)
	return string.format("http://%s:%d/%s", DOCKER_HOSTNAME, DOCKER_PORT, path)
end

-- TODO : At the moment, only RequestGameServer needs to be part of the public API,
-- whereas the rest of the functions are utility and could be changed to local,
-- however I will leave them as such until I know for sure I won't need them exposed

-- Create, start, and retrieve the public/external port of a Game Server container
-- returns the port that the clients should connect to
function M.RequestGameServer(matchid)
	local port = M.GetFreePort()
	
	if port == -1 then
		error("No servers available.")
	else
		local success, containerId = pcall(M.CreateContainer, port, matchid)
		if (not success) then
			nk.logger_error(string.format("Failure to create container: %q", containerId))
			error(containerId)
		else
			local success, actualPort = pcall(M.StartContainer, containerId)
			if (not success) then
				nk.logger_error(string.format("Failure to start container: %q", actualPort))
				error(actualPort)
			else
				return actualPort
			end
		end
	end
end

-- Helper function to derive a free port within a given range based on actual running containers
-- Returns an unused port number
function M.GetFreePort()
	local runningGameServers = M.GetServerPool()
	for port = minPort, maxPort, 1 do
		local available = true
		for _, container in ipairs(runningGameServers) do
			if container["Port"] == port then
				available = false
				break
			end
		end
		if available then
			return port
		end
	end
	
	return -1
end

-- Helper function to get a list of actual running containers of a specific image (hardcoded atm)
-- returns a list of containers and their ports
-- TODO : Perhaps simplify this to return a list of used external ports. This is more valuable than all the extra junk
function M.GetServerPool()
	local gameServerContainers = {}
	local path = "containers/json"
	local url = GetUrl(path)
	local method = "GET"
	local headers = {
		["Accept"] = "application/json"
	}
	
	local success, code, _, body = pcall(nk.http_request, url, method, headers, nil)
	if (not success) then
		nk.logger_error(string.format("Failed request %q", code))
		error(code)
	elseif (code >= 400) then
		nk.logger_error(string.format("Failed request %q %q", code, body))
		error(body)
	else
		local containerList = nk.json_decode(body)
		for containerIndex in pairs(containerList) do
			local container = containerList[containerIndex]
			if container["Image"] == "victordavion/ddags:latest" then
				local ports = container["Ports"]
				local port = ports[1]
				table.insert(gameServerContainers, {
					["Port"] = port["PublicPort"],
					["Container"] = container
				})
			end
		end
	end
	
	return gameServerContainers
end

-- Create a container of a specific (hardcoded) image exposing the port on both tcp/udp
-- returns the container id
function M.CreateContainer(port, matchid)
	local path = "containers/create"
	local url = GetUrl(path)
	local method = "POST"
	local content = nk.json_encode({
		["Image"] = "victordavion/ddags:latest",
		["Env"] = {
			string.format("AUTHIP=%s", nakamaIp),
			string.format("AUTHPORT=%d", nakamaPort),
			string.format("EXTPORT=%d", port),
			string.format("MATCHID=%s", matchid),
			"SERVER=true",
			"NOMATCHMAKING=0"
		},
		["HostConfig"] = {
			["AutoRemove"] = true,
			["NetworkMode"] = "roachnet",
			["PortBindings"] = {
				["9000/tcp"] = {
					{
						["HostIp"] = "0.0.0.0",
						["HostPort"] = string.format("%d", port)
					}
				},
				["9000/udp"] = {
					{
						["HostIp"] = "0.0.0.0",
						["HostPort"] = string.format("%d", port)
					}
				}
			}
		}
	})
	local headers = {
		["Content-Type"] = "application/json",
		["Content-Length"] = string.format("%d", string.len(content))
	}
	
	local success, code, _, body = pcall(nk.http_request, url, method, headers, content)
	if (not success) then
		nk.logger_error(string.format("Failed request %q", code))
		error(code)
	elseif (code >= 400) then
		nk.logger_error(string.format("Failed request %q %q", code, body))
		error(body)
	else
		local containerId = nk.json_decode(body)["Id"]
		return containerId
	end
	
end

-- Starts a given container id
-- returns The external port that the container was assigned
function M.StartContainer(id)
	local path = string.format("containers/%s/start", id)
	local url = GetUrl(path)
	local method = "POST"
	local headers = {
		["Content-Type"] = "application/json",
		["Content-Length"] = "0"
	}
	
	local success, code, _, body = pcall(nk.http_request, url, method, headers, nil)
	if (not success) then
		nk.logger_error(string.format("Failed request %q", code))
		error(code)
	elseif (code >= 400) then
		nk.logger_error(string.format("Failed request %q %q", code, body))
		error(body)
	else
		return M.GetContainerPort(id)
	end
end

-- Gets the external port for clients to connect to after the container has started
-- returns A port
-- TODO : This may be overly complex, as prior to a refactor (from which this was ported from),
-- the ports were dynamically assigned by Docker. Instead, with the current api, the ports are
-- decided upon prior to creating the container.
function M.GetContainerPort(id)
	local path = string.format("containers/%s/json", id)
	local url = GetUrl(path)
	local method = "GET"
	local headers = {
		["Accept"] = "application/json"
	}
	
	local success, code, _, body = pcall(nk.http_request, url, method, headers, nil)
	if (not success) then
		nk.logger_error(string.format("Failed request %q", code))
		error(code)
	elseif (code >= 400) then
		nk.logger_error(string.format("Failed request %q %q", code, body))
		error(body)
	else
		local container = nk.json_decode(body)
		local port = container["NetworkSettings"]["Ports"]["9000/tcp"][1]["HostPort"]
		return port
	end
end

return M
