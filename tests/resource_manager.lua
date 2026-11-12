local ResourceManager = require("engine.resources.resourceManager")

local definition = { type = "image", path = "player.png" }
local loadCount = 0
local releaseCount = 0
local released = {}
local manager = ResourceManager.new({ player = definition }, {
	image = {
		load = function(passedDefinition)
			assert(passedDefinition == definition)
			loadCount = loadCount + 1
			return {}
		end,
		release = function(resource)
			releaseCount = releaseCount + 1
			table.insert(released, resource)
		end,
	},
})

local firstConsumer = {}
local secondConsumer = {}
local loaded = manager:get(firstConsumer, "player")
assert(manager:get(secondConsumer, "player") == loaded)
assert(manager:get(firstConsumer, "player") == loaded)
assert(loadCount == 1)
assert(manager.resources.player.resource == loaded)
assert(manager.resources.player.consumers[firstConsumer])
assert(manager.resources.player.consumers[secondConsumer])

manager:release({}, "player")
manager:release(firstConsumer, "missing")
assert(releaseCount == 0 and manager.resources.player.resource == loaded)
manager:release(firstConsumer, "player")
assert(not manager.resources.player.consumers[firstConsumer])
assert(manager.resources.player.consumers[secondConsumer])
assert(releaseCount == 0)
manager:release(firstConsumer, "player")
assert(releaseCount == 0 and manager.resources.player.resource == loaded)
manager:release(secondConsumer, "player")
assert(releaseCount == 1 and manager.resources.player == nil)
assert(released[1] == loaded)
manager:release(secondConsumer, "player")
assert(releaseCount == 1)

local reloaded = manager:get(firstConsumer, "player")
assert(reloaded ~= loaded and loadCount == 2)
assert(manager.resources.player.resource == reloaded)
manager:releaseResource("player")
assert(releaseCount == 2 and manager.resources.player == nil)
assert(released[2] == reloaded)
manager:releaseResource("player")
assert(releaseCount == 2)

local success, message = pcall(function()
	manager:get(firstConsumer, "missing")
end)
assert(not success and type(message) == "string" and message:find("Resource 'missing' is not defined", 1, true))
assert(manager.resources.missing == nil)
assert(loadCount == 2)

manager.definitions.other = definition
local shared = manager:get(firstConsumer, "player")
assert(manager:get(secondConsumer, "player") == shared)
local other = manager:get(secondConsumer, "other")
manager:releaseAllResources()
assert(next(manager.resources) == nil and releaseCount == 4)
assert((released[3] == shared and released[4] == other)
	or (released[3] == other and released[4] == shared))
manager:releaseAllResources()
assert(releaseCount == 4)
local afterClear = manager:get(firstConsumer, "player")
assert(afterClear ~= shared and loadCount == 5)
manager:releaseAllResources()
assert(next(manager.resources) == nil and releaseCount == 5)

local missingLoaderManager = ResourceManager.new({ music = { type = "audio" } }, {})
success, message = pcall(function()
	missingLoaderManager:get(firstConsumer, "music")
end)
assert(not success and type(message) == "string" and message:find("No loader registered for resource type 'audio'", 1, true))
assert(missingLoaderManager.resources.music == nil)

print("resource manager tests passed")