local ResourceManager = require("engine.resources.resourceManager")
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
local imageCount = 0
local paths = {}
for resourceId, definition in pairs(definitions) do
	if definition.type == "image" then
		local file = assert(io.open(definition.path, "rb"), resourceId .. ": " .. definition.path)
		file:close()
		assert(not paths[definition.path], "duplicate image path: " .. definition.path)
		paths[definition.path] = true
		local image = manager:get(consumer, resourceId)
		assert(image.path == definition.path)
		assert(manager:get(consumer, resourceId) == image)
		imageCount = imageCount + 1
	end
end
assert(#images == imageCount and imageCount > 0)
local font = manager:get(consumer, "pause_font")
assert(font.size == definitions.pause_font.size)
manager:releaseAll(consumer)
for _, image in ipairs(images) do assert(image.released) end
assert(font.released)
assert(next(manager.resources) == nil)

print("resource loader tests passed")
