local SceneLoader = require("lua.engine.scene.sceneLoader")
local SceneManager = require("lua.engine.scene.sceneManager")

local loader = SceneLoader.new()

local manager = SceneManager.new(loader)


function love.load()
	love.window.setMode(1280, 720, { vsync = true, fullscreen = false })

    manager:push("mainMenu")
end

function love.update(dt)
    manager:update(dt)
end

function love.draw()
    manager:draw()
end
