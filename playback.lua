local mp = require("mp")
local playback = {
	loaded = false,
}

local function findIndex(isPreloaded, session, filename)
	if not filename then
		return 1
	end

	local epList = mp.get_property_native("playlist", {})
	local ep = nil

	if isPreloaded then
		ep = "./" .. filename
	else
		ep = session .. "/" .. filename
	end

	local lo, hi = 1, #epList

	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		local curr = epList[mid]

		if curr.filename == ep then
			return mid
		elseif curr.filename < ep then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
	return 1
end

function playback:new(params)
	if not params.session then
		return
	end
	local timeout = 0.25
	if not params.isPreloaded then
		mp.commandv("loadlist", params.session, "replace")
		timeout = 0.5
	end

	mp.add_timeout(timeout, function()
		local index = findIndex(params.isPreloaded, params.session, params.filename)
		if index > 1 then
			mp.set_property("playlist-pos", index - 1)
		end

		if params["time-pos"] then
			mp.add_timeout(0.1, function()
				mp.commandv("seek", math.max(params["time-pos"] - 5, 0), "absolute", "exact")
				if params.aid then
					mp.set_property("aid", params.aid)
				end

				if params.sid then
					mp.set_property("sid", params.sid)
				end

				playback.loaded = true
			end)
		else
			playback.loaded = true
		end
	end)
end

return playback
