local utils = require("engine.graphics.utils")
local image = { getDimensions = function() return 32, 16 end }
love = {
	graphics = {
		newQuad = function(...) return { ... } end,
	},
}

local tileset = utils.loadQuads(image, 16, 16)
assert(tileset.image == image and #tileset.quads == 2)
assert(tileset.quads[1][1] == 0 and tileset.quads[2][1] == 16)
local animation = utils.loadAnimation(image, 16, 16, 0.1)
assert(animation.image == image and #animation.frames == 2 and animation.frameDuration == 0.1)
assert(animation.frames[1][1] == 0 and animation.frames[2][1] == 16)
print("graphics utils tests passed")