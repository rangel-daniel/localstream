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

function data:enableSkip()
	if not playback.loaded then
		return
	end

	local curr = data[activeSession]["skip-enabled"] or false
	local new = not curr

	data[activeSession]["skip-enabled"] = new

	mp.osd_message("Skip intro " .. (new and "enabled!" or "disabled!"))
end

function data:setIntroLen(binding)
	if not playback.loaded then
		return
	end

	local message = "'Skip intro' is disabled, press " .. binding .. " to enable."

	if data[activeSession]["skip-enabled"] then
		local pos = data[activeSession]["time-pos"]

		data[activeSession]["intro-len"] = pos
		message = "Intro length set!"
	end

	mp.osd_message(message, 5)
end

function data:displaySkipMsg(binding)
	local enabled = data[activeSession]["skip-enabled"]
	local introLen = data[activeSession]["intro-len"]
	if enabled and introLen then
		local pos = data[activeSession]["time-pos"]
		local duration = introLen - pos

		duration = math.min(duration, 10)

		if duration > 0 then
			mp.osd_message("Skip intro (press " .. binding .. ")", duration)
		end
	end
end

function data:skipIntro()
	local enabled = data[activeSession]["skip-enabled"]
	local introLen = data[activeSession]["intro-len"]
	local pos = data[activeSession]["time-pos"]

	if enabled and introLen and introLen > pos then
		mp.commandv("seek", introLen, "absolute", "exact")

		mp.osd_message("", 1)
	end
end
return data
