local mp = require("mp")
local data = require("data")

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

mp.register_event("end-file", data.save)
