local mp = require("mp")
local data = require("data")

local bindings = {
	["enable-skip"] = "Alt+n",
	["set-intro-len"] = "Ctrl+n",
	["skip-intro"] = "n",
}

data:load()

mp.observe_property("time-pos", "number", function(name, value)
	if value then
		data:updateSessionData(name, value)
	end
end)

mp.observe_property("filename", "string", function(name, value)
	if value then
		data:updateSessionData(name, value)
	end
end)

mp.observe_property("aid", "number", function(name, value)
	if value then
		data:updateSessionData(name, value)
	end
end)

mp.observe_property("sid", "number", function(name, value)
	if value then
		data:updateSessionData(name, value)
	end
end)

mp.add_key_binding(bindings["enable-skip"], "enable-skip", data.enableSkip)

mp.add_key_binding(bindings["set-intro-len"], "set-intro-len", function()
	data:setIntroLen(bindings["enable-skip"])
end)

mp.add_key_binding(bindings["skip-intro"], "skip-intro", data.skipIntro)

mp.register_event("start-file", function()
	mp.add_timeout(0.1, function()
		data:displaySkipMsg(bindings["skip-intro"])
	end)
end)

mp.register_event("end-file", data.save)
