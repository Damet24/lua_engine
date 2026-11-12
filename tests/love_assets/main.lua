local root = assert(os.getenv("ENGINE_TEST_ROOT"))
package.path = root .. "/?.lua;" .. package.path

local definitions = require("game.resources.definitions")
local loaders = require("game.resources.loaders")
local ResourceManager = require("engine.resources.resourceManager")

rawset(love, "load", function()
	local ok, message = xpcall(function()
		local originalNewImage = love.graphics.newImage
		rawset(love.graphics, "newImage", function(path)
			local file = assert(io.open(root .. "/" .. path, "rb"))
			local data = file:read("*a")
			file:close()
			return originalNewImage(love.filesystem.newFileData(data, path))
		end)
		local manager = ResourceManager.new(definitions, loaders)
		local consumer = {}
		local count = 0
		for id, definition in pairs(definitions) do
			if definition.type == "image" then
				local image = manager:get(consumer, id)
				assert(image:getWidth() > 0 and image:getHeight() > 0, "invalid image: " .. id)
				manager:release(consumer, id)
				count = count + 1
			end
		end
		assert(count > 0 and next(manager.resources) == nil)
		print("LÖVE image assets tests passed: " .. count .. " images")
	end, debug.traceback)
	if not ok then io.stderr:write(message .. "\n") end
	love.event.quit(ok and 0 or 1)
end)