local Components = require("lua.engine.ecs.component")

local PhysicsMovementSystem = {}

function PhysicsMovementSystem.update(world)
	world:query({ Components.RigidBody, Components.Velocity }, function(entity, components)
		local rigidBody = components.RigidBody
		local body = rigidBody.body
		if not body or body:getType() == "static" then return end
		local velocity = components.Velocity
		local movement = world:getComponent(entity, Components.Movement)
		local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
		local scale = movement and movement.maxSpeed and speed > movement.maxSpeed and speed > 0
			and math.max(0, movement.maxSpeed) / speed or 1
		local velocityX, velocityY = velocity.x * scale, velocity.y * scale
		if rigidBody.commandX ~= velocityX or rigidBody.commandY ~= velocityY then
			body:setLinearVelocity(velocityX, velocityY)
			rigidBody.commandX, rigidBody.commandY = velocityX, velocityY
		end
	end)
end

return PhysicsMovementSystem