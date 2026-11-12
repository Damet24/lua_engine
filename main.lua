local Engine = require("lua.engine.engine")

local resourcesDefinitions = require("game.resources.definitions")
local resourcesLoaders = require("game.resources.loaders")

local engine = Engine.new({
	initialScene = "mainMenu",
	resourceDefinitions = resourcesDefinitions,
	resourceLoaders = resourcesLoaders,
	window = {
		width = 1280,
		height = 720,
		fullscreen = false,
		resizable = false,
		vsync = true,
	},

	rendering = {
		width = 640,
		height = 360,
		pixelPerfect = true,
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
