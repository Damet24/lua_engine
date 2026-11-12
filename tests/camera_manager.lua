local CameraManager = require("engine.camera.cameraManager")
local manager = CameraManager.new()
assert(manager:getActive() == nil)
local gameplay = manager:add("gameplay", { x = 20 })
local minimap = manager:add("minimap", { zoom = 0.25 })
assert(manager:get("gameplay") == gameplay and manager:get("minimap") == minimap)
assert(manager:getActive() == nil)
manager:setActive("gameplay")
assert(manager:getActive() == gameplay)
manager:setActive("minimap")
assert(manager:getActive() == minimap)
manager:remove("minimap")
assert(manager:getActive() == nil and manager:get("gameplay") == gameplay)
for _, action in ipairs({
	function() manager:add("gameplay") end,
	function() manager:get("missing") end,
	function() manager:setActive("missing") end,
	function() manager:remove("missing") end,
	function() manager:add("") end,
}) do
	local ok, message = pcall(action)
	assert(not ok and type(message) == "string" and message:find("camera", 1, true))
end
print("camera manager tests passed")