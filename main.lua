local Engine = require("engine.engine")

local resourcesDefinitions = require("game.resources.definitions")
local inputMaps = require("game.inputMaps")

local engine = Engine.new({
	initialScene = "levels.level01",
	resourceDefinitions = resourcesDefinitions,
	inputMaps = inputMaps,
	window = {
		width = 256*3,
		height = 240*3,
		fullscreen = false,
		resizable = false,
		vsync = true,
	},

	rendering = {
		width = 256,
		height = 240,
		pixelPerfect = true,
		backgroundColor = { 0.18, 0.25, 0.34 },
	},
})

function love.load()
	engine:load()
end

function love.update(dt)
	engine:update(dt)
end

function love.draw()
	engine:draw()
end

function love.keypressed(key)
	engine:keypressed(key)
end

function love.keyreleased(key)
	engine:keyreleased(key)
end
