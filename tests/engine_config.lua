local Engine = require("lua.engine.engine")

local engine = Engine.new({ initialScene = "menu" })
assert(engine.config.initialScene == "menu" and engine.config.scenesPath == "game.scenes")
assert(engine.sceneLoader.scenesPath == "game.scenes" and engine.window == nil)
assert(engine.rendering.width == 1280 and engine.rendering.height == 720)
assert(engine.rendering.pixelPerfect == false)
assert(type(engine.config.resourceDefinitions) == "table")
assert(type(engine.config.resourceLoaders) == "table")

local config = {
	initialScene = "menu", scenesPath = "custom.scenes",
	window = { width = 1920, height = 1080, resizable = false, vsync = false },
	rendering = { width = 640, pixelPerfect = true },
	resourceDefinitions = {}, resourceLoaders = {},
}
engine = Engine.new(config)
assert(engine.config ~= config and engine.window ~= config.window and engine.rendering ~= config.rendering)
assert(config.window.fullscreen == nil and config.rendering.height == nil)
assert(engine.window.fullscreen == false and engine.window.resizable == false and engine.window.vsync == false)
assert(engine.rendering.width == 640 and engine.rendering.height == 720 and engine.rendering.pixelPerfect == true)
assert(engine.sceneLoader.scenesPath == "custom.scenes")
assert(engine.resourceManager.definitions == config.resourceDefinitions)
assert(engine.resourceManager.loaders == config.resourceLoaders)

local function invalid(configValue, expected)
	local success, message = pcall(Engine.new, configValue)
	assert(not success and tostring(message):find(expected, 1, true), tostring(message))
end

invalid(false, "config")
invalid({}, "initialScene")
invalid({ initialScene = "" }, "initialScene")
invalid({ initialScene = 1 }, "initialScene")
invalid({ initialScene = "menu", scenesPath = "" }, "scenesPath")
invalid({ initialScene = "menu", scenesPath = false }, "scenesPath")
invalid({ initialScene = "menu", window = false }, "window")
invalid({ initialScene = "menu", rendering = false }, "rendering")
invalid({ initialScene = "menu", resourceDefinitions = false }, "resourceDefinitions")
invalid({ initialScene = "menu", resourceLoaders = "bad" }, "resourceLoaders")
invalid({ initialScene = "menu", window = { width = 100 } }, "window.height")
invalid({ initialScene = "menu", window = { height = 100 } }, "window.width")
for _, value in ipairs({ 0, -1, 1.5, math.huge, "100", false }) do
	invalid({ initialScene = "menu", window = { width = value, height = 100 } }, "window.width")
	invalid({ initialScene = "menu", window = { width = 100, height = value } }, "window.height")
	invalid({ initialScene = "menu", rendering = { width = value } }, "rendering.width")
	invalid({ initialScene = "menu", rendering = { height = value } }, "rendering.height")
end
for _, key in ipairs({ "fullscreen", "resizable", "vsync" }) do
	local window = { width = 100, height = 100 }
	window[key] = 1
	invalid({ initialScene = "menu", window = window }, "window." .. key)
end
invalid({ initialScene = "menu", rendering = { pixelPerfect = "false" } }, "rendering.pixelPerfect")

print("engine config tests passed")