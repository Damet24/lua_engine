local Components = require("lua.engine.ecs.component")

local PhysicsSyncSystem = {}

local PIXELS_PER_METER = 64

function PhysicsSyncSystem.update(world)
	world:query({

	}, function(entity, components)
		
	end)
end

return PhysicsSyncSystem
