local ResourceManager = require("engine.resources.resourceManager")
local GameContext = require("engine.core.gameContext")
local SceneLoader = require("engine.scene.sceneLoader")
local SceneManager = require("engine.scene.sceneManager")

local releases = 0
local resourceManager = ResourceManager.new({ shared = { type = "test" }, pause_font = { type = "font" } }, {
	test = {
		load = function() return {} end,
		release = function() releases = releases + 1 end,
	},
	font = { load = function() return {} end, release = function() end },
})
local context = GameContext.new({
	resourceManager = resourceManager,
	audioManager = {
		playMusic = function() end,
		playSound = function() return 0 end,
		update = function() end,
		shutdown = function() end,
	},
})
local loader = SceneLoader.new({ context = context })
local manager = SceneManager.new(loader)
context.sceneManager = manager
context.inputManager = {
	isDown = function() return false end,
	isJustPressed = function() return false end,
	isJustReleased = function() return false end,
}

love = {
	keyboard = { isDown = function() return false end },
	graphics = { newFont = function() return {} end },
}

assert(context.resourceManager == resourceManager)
local level = loader:load("levels.level01")
assert(level.context == context)
manager:push("mainMenu")
manager:update(0)
assert(manager.stack[1].scene.context == context)
local menu = manager.stack[1].scene
local shared = resourceManager:get(menu, "shared")
assert(resourceManager:get(level, "shared") == shared)
manager:push("pause")
manager:update(0)
assert(manager.stack[2].scene.context == context)
local pause = manager.stack[2].scene
assert(resourceManager:get(pause, "shared") == shared)
manager:pop()
manager:update(0)
assert(#manager.stack == 1 and manager.stack[1].scene.context == context)
assert(not resourceManager.resources.shared.consumers[pause] and releases == 0)
level:onDestroy()
assert(not resourceManager.resources.shared.consumers[level] and releases == 0)
manager:pop()
manager:update(0)
assert(resourceManager.resources.shared == nil and releases == 1)

print("scene context tests passed")