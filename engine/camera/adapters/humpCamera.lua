local HumpCamera = require("engine.lib.hump.camera")

---@class HumpCameraAdapter
---@field camera any
local Adapter = {}
Adapter.__index = Adapter

function Adapter.new(config)
	config = config or {}
	local zoom = config.zoom or 1
	assert(type(zoom) == "number" and zoom > 0, "camera zoom must be positive")
	local self = setmetatable({
		camera = HumpCamera(config.x or 0, config.y or 0, zoom, config.rotation or 0),
		attached = false,
	}, Adapter)
	self:setViewport(config.viewport)
	return self
end

function Adapter:getViewport()
	local viewport = self.viewport or {}
	return viewport.x or 0, viewport.y or 0,
		viewport.width or love.graphics.getWidth(), viewport.height or love.graphics.getHeight()
end

function Adapter:setViewport(viewport)
	assert(not self.attached, "cannot change viewport while camera is attached")
	assert(viewport == nil or type(viewport) == "table", "camera viewport must be a table")
	if viewport then
		assert(type(viewport.width) == "number" and viewport.width > 0, "camera viewport width must be positive")
		assert(type(viewport.height) == "number" and viewport.height > 0, "camera viewport height must be positive")
	end
	self.viewport = viewport
end

function Adapter:setPosition(x, y) self.camera:lookAt(x, y) end
function Adapter:getPosition() return self.camera:position() end
function Adapter:move(dx, dy) self.camera:move(dx, dy) end
function Adapter:setZoom(zoom)
	assert(type(zoom) == "number" and zoom > 0, "camera zoom must be positive")
	self.camera:zoomTo(zoom)
end
function Adapter:getZoom() return self.camera.scale end
function Adapter:setRotation(rotation) self.camera:rotateTo(rotation) end
function Adapter:getRotation() return self.camera.rot end

function Adapter:attach()
	assert(not self.attached, "camera is already attached")
	local x, y, width, height = self:getViewport()
	local graphics = love.graphics
	local depth = graphics.getStackDepth()
	local ok, message = xpcall(function()
		graphics.push("all")
		if self.viewport and self.viewport.clip then
			local left, top = graphics.transformPoint(x, y)
			local _, horizontalY = graphics.transformPoint(x + width, y)
			local verticalX = graphics.transformPoint(x, y + height)
			assert(math.abs(horizontalY - top) < 0.0001 and math.abs(verticalX - left) < 0.0001,
				"clipped camera viewport requires an axis-aligned outer transform")
			local right, bottom = graphics.transformPoint(x + width, y + height)
			graphics.intersectScissor(math.min(left, right), math.min(top, bottom), math.abs(right - left), math.abs(bottom - top))
		end
		self.camera:attach(x, y, width, height, true)
	end, debug.traceback)
	if not ok then
		while graphics.getStackDepth() > depth do graphics.pop() end
		error(message, 0)
	end
	self.attached = true
	self.stackDepth = graphics.getStackDepth()
end

function Adapter:detach()
	assert(self.attached, "camera is not attached")
	assert(love.graphics.getStackDepth() >= self.stackDepth, "camera graphics stack was popped prematurely")
	while love.graphics.getStackDepth() > self.stackDepth do love.graphics.pop() end
	self.camera:detach()
	love.graphics.pop()
	self.attached = false
	self.stackDepth = nil
end

function Adapter:worldCoords(x, y)
	return self.camera:worldCoords(x, y, self:getViewport())
end

function Adapter:cameraCoords(x, y)
	return self.camera:cameraCoords(x, y, self:getViewport())
end

function Adapter:draw(draw)
	assert(type(draw) == "function", "camera draw requires a function")
	self:attach()
	local ok, result = xpcall(draw, debug.traceback)
	self:detach()
	if not ok then error(result, 0) end
end

return Adapter