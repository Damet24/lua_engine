local Components = require("engine.ecs.component")

local MovementSystem = {}

function MovementSystem.update(world, dt)
	world:query({ Components.Transform, Components.Velocity }, function(entity, components)
		if world:hasComponent(entity, Components.RigidBody) then
			return
		end

		local velocity = components.Velocity
		local movement = world:getComponent(entity, Components.Movement)
		local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
		local scale = movement and movement.maxSpeed and speed > movement.maxSpeed and speed > 0
			and math.max(0, movement.maxSpeed) / speed or 1
		components.Transform.x = components.Transform.x + velocity.x * scale * dt
		components.Transform.y = components.Transform.y + velocity.y * scale * dt
	end)
end

return MovementSystem
