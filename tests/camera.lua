local called = {}
local methods = {
	"setPosition", "getPosition", "move", "setZoom", "getZoom", "setRotation", "getRotation",
	"setViewport", "getViewport", "attach", "detach", "worldCoords", "cameraCoords", "draw",
}
local adapter = {}
for _, method in ipairs(methods) do
	adapter[method] = function(_, ...)
		called[method] = { ... }
		return "first", "second"
	end
end
local config = { x = 10 }
package.loaded["engine.camera.adapters.humpCamera"] = {
	new = function(value) assert(value == config); return adapter end,
}
local Camera = require("engine.camera.camera")
local camera = Camera.new(config)
local argumentCounts = { setPosition = 2, move = 2, setZoom = 1, setRotation = 1,
	setViewport = 1, worldCoords = 2, cameraCoords = 2, draw = 1 }
for _, method in ipairs(methods) do
	local first, second = camera[method](camera, 12, 34)
	local count = argumentCounts[method] or 0
	assert(#called[method] == count)
	if count >= 1 then assert(called[method][1] == 12) end
	if count == 2 then assert(called[method][2] == 34) end
	if method:match("^get") or method == "worldCoords" or method == "cameraCoords" or method == "draw" then
		assert(first == "first" and second == "second")
	end
end
print("camera interface tests passed")