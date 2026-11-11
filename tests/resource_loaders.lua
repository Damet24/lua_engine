local ResourceManager = require("lua.engine.resources.resourceManager")
local definitions = require("game.resources.definitions")
local loaders = require("game.resources.loaders")

local images = {}
love = {
	graphics = {
		newImage = function(path)
			local image = { path = path, released = false }
			function image:release()
				assert(not self.released)
				self.released = true
			end
			table.insert(images, image)
			return image
		end,
		newFont = function(size)
			return { size = size, release = function(self) self.released = true end }
		end,
	},
}

local manager = ResourceManager.new(definitions, loaders)
local consumer = {}
for _, resourceId in ipairs({ "terrain", "player_idle" }) do
	local image = manager:get(consumer, resourceId)
	assert(image.path == definitions[resourceId].path)
	assert(manager:get(consumer, resourceId) == image)
end
assert(#images == 2)
local font = manager:get(consumer, "pause_font")
assert(font.size == definitions.pause_font.size)
manager:releaseAll(consumer)
assert(images[1].released and images[2].released)
assert(font.released)
assert(next(manager.resources) == nil)

print("resource loader tests passed")