local ResourceManager = require("engine.resources.resourceManager")
local GameContext = require("engine.gameContext")
local SceneLoader = require("engine.scene.sceneLoader")
local SceneManager = require("engine.scene.sceneManager")
local InputManager = require("engine.input.inputManager")

local Engine = {}
Engine.__index = Engine

local function normalizeConfig(config)
	assert(type(config) == "table", "config must be a table")

	local normalized = {}
	for key, value in pairs(config) do
		normalized[key] = value
	end

	local function withDefaults(value, defaults, name)
		if value == nil then
			value = {}
		end
		assert(type(value) == "table", name .. " must be a table")
		local result = {}
		for key, item in pairs(value) do
			result[key] = item
		end
		for key, default in pairs(defaults) do
			if result[key] == nil then
				result[key] = default
			end
		end
		return result
	end

	if normalized.scenesPath == nil then
		normalized.scenesPath = "game.scenes"
	end
	if normalized.resourceDefinitions == nil then
		normalized.resourceDefinitions = {}
	end
	if normalized.resourceLoaders == nil then
		normalized.resourceLoaders = {}
	end
	if normalized.window ~= nil then
		normalized.window = withDefaults(normalized.window, {
			fullscreen = false,
			resizable = true,
			vsync = true,
		}, "window")
	end
	normalized.rendering = withDefaults(normalized.rendering, {
		width = 1280,
		height = 720,
		pixelPerfect = false,
		backgroundColor = { 0, 0, 0, 1 },
	}, "rendering")
	return normalized
end

local function validateConfig(config)
	local function nonemptyString(value, name)
		assert(type(value) == "string" and #value > 0, name .. " must be a non-empty string")
	end

	local function dimension(value, name)
		assert(
			type(value) == "number" and value > 0 and value < math.huge and value == math.floor(value),
			name .. " must be a positive integer"
		)
	end

	local function boolean(value, name)
		assert(type(value) == "boolean", name .. " must be a boolean")
	end

	nonemptyString(config.initialScene, "initialScene")
	nonemptyString(config.scenesPath, "scenesPath")
	assert(type(config.resourceDefinitions) == "table", "resourceDefinitions must be a table")
	assert(type(config.resourceLoaders) == "table", "resourceLoaders must be a table")
	if config.window then
		dimension(config.window.width, "window.width")
		dimension(config.window.height, "window.height")
		boolean(config.window.fullscreen, "window.fullscreen")
		boolean(config.window.resizable, "window.resizable")
		boolean(config.window.vsync, "window.vsync")
	end
	dimension(config.rendering.width, "rendering.width")
	dimension(config.rendering.height, "rendering.height")
	boolean(config.rendering.pixelPerfect, "rendering.pixelPerfect")
	local color = config.rendering.backgroundColor
	assert(type(color) == "table", "rendering.backgroundColor must be an RGB or RGBA array")
	local count = 0
	for index, value in pairs(color) do
		assert(type(index) == "number" and index >= 1 and index <= 4 and index == math.floor(index),
			"rendering.backgroundColor must be an RGB or RGBA array")
		assert(type(value) == "number" and value >= 0 and value <= 1,
			"rendering.backgroundColor components must be between 0 and 1")
		count = count + 1
	end
	assert((count == 3 or count == 4) and color[1] ~= nil and color[2] ~= nil and color[3] ~= nil,
		"rendering.backgroundColor must be an RGB or RGBA array")
	config.rendering.backgroundColor = { color[1], color[2], color[3], color[4] == nil and 1 or color[4] }
end

function Engine.new(config)
	if config == nil then
		config = {}
	end
	config = normalizeConfig(config)
	validateConfig(config)

	local self = setmetatable({}, Engine)

	self.config = config
	self.initialScene = config.initialScene

	self.window = config.window
	self.rendering = config.rendering

	self.resourceManager = ResourceManager.new(config.resourceDefinitions, config.resourceLoaders)

	self.context = GameContext.new({
		resourceManager = self.resourceManager,
	})

	self.sceneLoader = SceneLoader.new({
		scenesPath = config.scenesPath,
		context = self.context,
	})

	self.sceneManager = SceneManager.new(self.sceneLoader)

	self.inputManager = InputManager.new(config.inputMaps)

	self.context.sceneManager = self.sceneManager
	self.context.inputManager = self.inputManager

	self.loaded = false
	self.closed = false

	return self
end

function Engine:load()
	assert(not self.loaded, "Engine is already loaded")
	assert(not self.closed, "Engine is already closed")

	if self.window then
		local window = self.window
		assert(
			love.window.setMode(window.width, window.height, {
				fullscreen = window.fullscreen,
				resizable = window.resizable,
				vsync = window.vsync,
			}),
			"Failed to set window mode"
		)
	end

	love.graphics.setBackgroundColor(unpack(self.rendering.backgroundColor))
	self.viewport = require("engine.lib.shove.shove")
	self.viewport.setResolution(self.rendering.width, self.rendering.height, {
		fitMethod = self.rendering.pixelPerfect and "pixel" or "aspect",
	})
	self.context.viewport = self.viewport

	self.sceneManager:push(self.initialScene)
	self.sceneManager:processPendingOperations()

	self.loaded = true
end

function Engine:update(dt)
	if not self.loaded or self.closed then
		return
	end

	self.sceneManager:update(dt)
	self.inputManager:update()
end

function Engine:draw()
	if not self.loaded or self.closed then
		return
	end

	self.viewport.beginDraw()
	self.sceneManager:draw()
	self.viewport.endDraw()
end

function Engine:quit()
	if self.closed then
		return
	end

	self.sceneManager:clear()
	self.sceneManager:processPendingOperations()

	self.resourceManager:releaseAllResources()

	self.closed = true
end

function Engine:keypressed(key)
	self.inputManager:keypressed(key)
end

function Engine:keyreleased(key)
	self.inputManager:keyreleased(key)
end

return Engine
