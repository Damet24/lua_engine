local root = assert(os.getenv("ENGINE_TEST_ROOT"))
package.path = root .. "/?.lua;" .. package.path

rawset(love, "run", function()
	local newImage = love.graphics.newImage
	rawset(love.graphics, "newImage", function(path)
		local file = assert(io.open(root .. "/" .. path, "rb"))
		local data = file:read("*a")
		file:close()
		return newImage(love.filesystem.newFileData(data, path))
	end)
	local ResourceManager = require("engine.resources.resourceManager")
	local GameContext = require("engine.core.gameContext")
	local SceneLoader = require("engine.scene.sceneLoader")
	local SceneManager = require("engine.scene.sceneManager")
	local resources = ResourceManager.new(require("game.resources.definitions"), require("game.resources.loaders"))
	local context = GameContext.new({
		resourceManager = resources,
		audioManager = {
			playMusic = function() end,
			playSound = function() return 0 end,
			update = function() end,
			shutdown = function() end,
		},
	})
	context.viewport = { getViewportDimensions = function() return 400, 300 end }
	context.inputManager = { isDown = function() return false end, isJustPressed = function() return false end }
	local manager = SceneManager.new(SceneLoader.new({ context = context }))
	context.sceneManager = manager

	manager:push("levels.level01")
	manager:update(0)
	local level = manager.stack[1].scene
	assert(resources.resources.terrain.consumers[level])
	assert(resources.resources.player_idle.consumers[level])
	manager:draw()
	manager:push("pause")
	manager:update(0)
	local pause = manager.stack[2].scene
	assert(resources.resources.pause_font.consumers[pause])
	manager:draw()
	manager:pop()
	manager:update(0)
	assert(resources.resources.pause_font == nil)
	assert(resources.resources.terrain and resources.resources.player_idle)
	manager:pop()
	manager:update(0)
	assert(next(resources.resources) == nil)
	print("LÖVE resource scene tests passed")
	return function() return 0 end
end)