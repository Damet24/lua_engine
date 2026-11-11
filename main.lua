local ResourceManager = require("lua.engine.resources.resourceManager")
local GameContext = require("lua.engine.gameContext")
local SceneLoader = require("lua.engine.scene.sceneLoader")
local SceneManager = require("lua.engine.scene.sceneManager")

local definitions = require("game.resources.definitions")
local loaders = require("game.resources.loaders")

local resourceManager = ResourceManager.new(definitions, loaders)
local context = GameContext.new({ resourceManager = resourceManager })
local sceneLoader = SceneLoader.new({ context = context })
local sceneManager = SceneManager.new(sceneLoader)
context.sceneManager = sceneManager

function love.load()
	love.window.setMode(1280, 720, { vsync = true, fullscreen = false })

    sceneManager:push("mainMenu")
end

function love.update(dt)
    sceneManager:update(dt)
end

function love.draw()
    sceneManager:draw()
end
