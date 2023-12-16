local mp = require("mp")
local utils = require("mp.utils")
local playback = require("playback")

local dataDir = mp.get_script_directory() .. "/saved-data.json"
local activeSession = nil
local isPreloaded = false
local data = {}

local function getSession()
	local isPlaylist = mp.get_property_native("playlist-count") > 0
	local workingDir = mp.get_property("working-directory")

	if isPlaylist then
		local entry = data[workingDir]

		if entry then
			isPreloaded = true
			print("Restoring session " .. "'" .. workingDir .. "' 🔄")
		else
			print("New session " .. "'" .. workingDir .. "' ⭐")
			data[workingDir] = {
				session = workingDir,
			}
		end
		data.prev = workingDir
		return workingDir
	end

	local prev = data.prev

	if prev and data[prev] then
		print("Restoring previous session " .. "'" .. prev .. "' 🔄")
		return prev
	end

	return nil
end

function data:load()
	local file = io.open(dataDir, "r")

	if not file then
		file = io.open(dataDir, "w")
		if file then
			file:write(" ")
			file:close()
		end
		file = io.open(dataDir, "r")
	end

	if file then
		local fileData = utils.parse_json(file:read("*all"))

		if fileData then
			data = fileData
		end

		file:close()
		activeSession = getSession()

		if activeSession then
			playback:new({
				session = activeSession,
				isPreloaded = isPreloaded,
				["time-pos"] = data[activeSession]["time-pos"],
				filename = data[activeSession].filename,
				aid = data[activeSession].aid,
				sid = data[activeSession].sid,
			})
		end
	end
end

function data:save()
	local file = io.open(dataDir, "w")
	if file then
		if playback.loaded then
			local _data = {}
			for key, value in pairs(data) do
				if type(value) ~= "function" then
					_data[key] = value
				end
			end
			file:write(utils.format_json(_data) or "")
			print("Saved progress! 💾")
		end
		file:close()
	end
end

function data:updateSessionData(name, value)
	if playback.loaded then
		data[activeSession][name] = value
	end
end

return data
