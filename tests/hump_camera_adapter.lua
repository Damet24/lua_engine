local depth, scissor = 0, nil
local stack = {}
love = { graphics = {
	getWidth = function() return 800 end,
	getHeight = function() return 600 end,
	getScissor = function() if scissor then return unpack(scissor) end end,
	setScissor = function(...) scissor = select("#", ...) > 0 and { ... } or nil end,
	intersectScissor = function(...) scissor = { ... } end,
	transformPoint = function(x, y) return x * 2 + 10, y * 2 + 20 end,
	getStackDepth = function() return depth end,
	push = function() depth = depth + 1; stack[depth] = scissor end,
	pop = function() scissor = stack[depth]; depth = depth - 1 end,
	translate = function() end,
	scale = function() end,
	rotate = function() end,
} }

local Adapter = require("engine.camera.adapters.humpCamera")
assert(not pcall(function() Adapter.new({ viewport = { width = 0, height = 100 } }) end))
local camera = Adapter.new({ x = 20, y = 30, zoom = 2, rotation = math.pi / 2 })
camera:setViewport({ x = 10, y = 20, width = 200, height = 100, clip = true })
local x, y = camera:cameraCoords(20, 30)
assert(x == 110 and y == 70)
x, y = camera:worldCoords(x, y)
assert(math.abs(x - 20) < 1e-9 and math.abs(y - 30) < 1e-9)
camera:setPosition(10, 15)
camera:move(2, 3)
x, y = camera:getPosition()
assert(x == 12 and y == 18)
camera:setZoom(3)
camera:setRotation(1)
assert(camera:getZoom() == 3 and camera:getRotation() == 1)
assert(not pcall(function() camera:setZoom(0) end))
camera:draw(function()
	assert(depth == 2)
	assert(scissor[1] == 30 and scissor[2] == 60 and scissor[3] == 400 and scissor[4] == 200)
end)
assert(depth == 0 and scissor == nil)
local ok, message = pcall(function() camera:draw(function() error("draw failed") end) end)
assert(not ok and message:find("draw failed", 1, true))
assert(depth == 0 and scissor == nil)
ok, message = pcall(function() camera:draw(function()
	love.graphics.push("all")
	error("nested draw failed")
end) end)
assert(not ok and message:find("nested draw failed", 1, true))
assert(depth == 0 and scissor == nil)
local transformPoint = love.graphics.transformPoint
love.graphics.transformPoint = function(x, y) return -y, x end
ok, message = pcall(function() camera:attach() end)
assert(not ok and message:find("axis-aligned", 1, true))
assert(depth == 0 and scissor == nil)
love.graphics.transformPoint = transformPoint
print("hump camera adapter tests passed")