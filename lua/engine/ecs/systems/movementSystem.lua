local Components = require("lua.engine.ecs.component")

local Movement = {}

function Movement.update(world, dt)
	world:query({ Components.Transform, Components.Velocity }, function(entity, components)
		local transform = components.Transform
		local velocity = components.Velocity

		transform.x = transform.x + velocity.x * dt
		transform.y = transform.y + velocity.y * dt
	end)
end

return Movement
