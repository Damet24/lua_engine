local calls = {}
local screenWidth, screenHeight = 1920, 1080
local resizeEvents = 0
unpack = unpack or table.unpack

package.preload["shove-profiler"] = function()
	return { init = function(profiler)
		profiler.profiler = { renderOverlay = function() end }
	end }
end

love = {
	handlers = { resize = function() resizeEvents = resizeEvents + 1 end },
	graphics = {
		getDimensions = function() return screenWidth, screenHeight end,
		setDefaultFilter = function(filter) calls.filter = filter end,
		newShader = function() return {} end,
		getColor = function() return 1, 1, 1, 1 end,
		setColor = function() end,
		setCanvas = function() end,
		push = function() table.insert(calls, "push") end,
		pop = function() table.insert(calls, "pop") end,
		translate = function(x, y) calls.offset = { x, y } end,
		scale = function(x, y) calls.scale = { x, y } end,
		setScissor = function() end,
	},
}

local Engine = require("engine.engine")
local engine = Engine.new({
	initialScene = "menu",
	rendering = { width = 640, height = 360, pixelPerfect = false },
})
engine.sceneManager = {
	push = function() end,
	processPendingOperations = function() end,
	draw = function() table.insert(calls, "scene") end,
}
engine:load()
assert(engine.context.viewport == engine.viewport)
assert(engine.viewport.getFitMethod() == "aspect" and calls.filter == "linear")
engine:draw()
assert(calls[1] == "push" and calls[2] == "scene" and calls[3] == "pop")
assert(calls.scale[1] == 3 and calls.scale[2] == 3)

screenWidth, screenHeight = 1000, 800
love.handlers.resize(screenWidth, screenHeight)
engine:draw()
assert(resizeEvents == 1 and calls.scale[1] == 1.5625 and calls.scale[2] == 1.5625)
assert(calls.offset[1] == 0 and calls.offset[2] == 118)

engine = Engine.new({ initialScene = "menu", rendering = { width = 640, height = 360, pixelPerfect = true } })
engine.sceneManager = { push = function() end, processPendingOperations = function() end, draw = function() end }
engine:load()
engine:draw()
assert(engine.viewport.getFitMethod() == "pixel" and calls.filter == "nearest")
assert(calls.scale[1] == 1 and calls.scale[2] == 1)
assert(calls.offset[1] == 180 and calls.offset[2] == 220)

print("engine rendering tests passed")