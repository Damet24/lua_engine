local Camera = require("lua.engine.camera.camera")

local CameraManager = {}
CameraManager.__index = CameraManager

local function validateId(id)
	assert(type(id) == "string" and id ~= "", "camera id must be a non-empty string")
end

function CameraManager.new()
	return setmetatable({ cameras = {}, active = nil }, CameraManager)
end

function CameraManager:add(id, config)
	validateId(id)
	assert(not self.cameras[id], "camera already exists: " .. id)
	local camera = Camera.new(config)
	self.cameras[id] = camera
	return camera
end

---@return Camera
function CameraManager:get(id)
	validateId(id)
	return assert(self.cameras[id], "camera does not exist: " .. id)
end

function CameraManager:setActive(id)
	self:get(id)
	self.active = id
end

---@return Camera|nil
function CameraManager:getActive()
	return self.active and self.cameras[self.active] or nil
end

function CameraManager:remove(id)
	self:get(id)
	self.cameras[id] = nil
	if self.active == id then self.active = nil end
end

return CameraManager