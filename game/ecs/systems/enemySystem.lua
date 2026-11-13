local Components = require("engine.ecs.component")

local ENEMY_SPEED = 60

local function isGrounded(body)
	for _, contact in ipairs(body:getContacts()) do
		if contact:isTouching() and contact:isEnabled() then
			local first, second = contact:getFixtures()
			if not first:isSensor() and not second:isSensor() then
				local _, normalY = contact:getNormal()
				if (first:getBody() == body and normalY > 0.5) or (second:getBody() == body and normalY < -0.5) then
					return true
				end
			end
		end
	end
	return false
end

local EnemySystem = {}

function EnemySystem.new(entity)
	return {
		update = function(world)
			local body = assert(world:getComponent(entity, Components.RigidBody)).body
			local velocity = assert(world:getComponent(entity, Components.Velocity))
			local _, velocityY = body:getLinearVelocity()
			velocity.x, velocity.y = -ENEMY_SPEED, velocityY
			body:setLinearVelocity(velocity.x, velocity.y)

			local animation = assert(world:getComponent(entity, Components.Animation))
			local animationName = isGrounded(body) and "run" or "fall"
			if animation.current ~= animationName then
				animation.current = animationName
				animation.frame = 1
				animation.timer = 0
				animation.playing = true
				animation.loop = true
			end
		end,
	}
end

return EnemySystem
