local Level = require("game.scenes.levels.level")
local map = require("game.maps.level02")

local Level02 = {}

function Level02.new(context)
	return Level.new(context, {
		map = map,
	})
end

return Level02