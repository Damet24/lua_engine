local Level = require("game.scenes.levels.level")
local map = require("game.maps.village")

local Level01 = {}

function Level01.new(context)
	return Level.new(context, {
        map = map,
		background ="background_blue",
		enemySpawns = { { x = 384, y = 192 } }
	})
end

return Level01
