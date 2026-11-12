local CameraAdapter = require("lua.engine.camera.adapters.humpCamera")

---@class Camera
---@field adapter HumpCameraAdapter
local Camera = {}
Camera.__index = Camera

---@return Camera
function Camera.new(config)
	return setmetatable({ adapter = CameraAdapter.new(config) }, Camera)
end

function Camera:setPosition(x, y) self.adapter:setPosition(x, y) end
function Camera:getPosition() return self.adapter:getPosition() end
function Camera:move(dx, dy) self.adapter:move(dx, dy) end
function Camera:setZoom(zoom) self.adapter:setZoom(zoom) end
function Camera:getZoom() return self.adapter:getZoom() end
function Camera:setRotation(rotation) self.adapter:setRotation(rotation) end
function Camera:getRotation() return self.adapter:getRotation() end
function Camera:setViewport(viewport) self.adapter:setViewport(viewport) end
function Camera:getViewport() return self.adapter:getViewport() end
function Camera:attach() self.adapter:attach() end
function Camera:detach() self.adapter:detach() end
function Camera:worldCoords(x, y) return self.adapter:worldCoords(x, y) end
function Camera:cameraCoords(x, y) return self.adapter:cameraCoords(x, y) end
function Camera:draw(draw) return self.adapter:draw(draw) end

return Camera