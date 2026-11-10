local Components = require("lua.engine.ecs.component")

local PhysicsSyncSystem = {}

function PhysicsSyncSystem.update(world)
	world:query({ Components.Transform, Components.RigidBody }, function(entity, components)
		local body = components.RigidBody.body
		if body then
			components.Transform.x, components.Transform.y = body:getPosition()
			components.Transform.rotation = body:getAngle()
		end
	end)
end

return PhysicsSyncSystem
