local SceneLoader = {}

SceneLoader.__index = SceneLoader

function SceneLoader.new(config)
    config = config or {}

    local self = setmetatable({}, SceneLoader)

    self.scenesPath = config.scenesPath or "game.scenes"
    self.context = assert(config.context, "context is required")

    return self
end

function SceneLoader:load(sceneName, dependencies)
	assert(type(sceneName) == "string", "sceneName must be a string")

	local modulePath = self.scenesPath .. "." .. sceneName

	local success, SceneClass = pcall(require, modulePath)

	if not success then
		error(("Failed to load scene '%s': %s"):format(sceneName, SceneClass), 2)
	end

	assert(
		type(SceneClass) == "table" and type(SceneClass.new) == "function",
		("Scene '%s' must return a class with a .new() constructor"):format(sceneName)
	)

	return SceneClass.new(self.context)
end

return SceneLoader
