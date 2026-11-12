local Components = require("engine.ecs.component")

local PLAYER_SPEED = 120
local JUMP_SPEED = 300
local MAX_JUMP = 2

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

local PlayerSystem = {}

function PlayerSystem.new(input, entity)
	local jumpCount = 0
	return {
		update = function(world, dt)
			local body = assert(world:getComponent(entity, Components.RigidBody)).body
			local velocity = assert(world:getComponent(entity, Components.Velocity))
			local direction = (input:isDown("move_right") and 1 or 0) - (input:isDown("move_left") and 1 or 0)
			if direction ~= 0 then
				local sprite = assert(world:getComponent(entity, Components.Sprite))
				sprite.flipH = direction < 0
			end
			local _, velocityY = body:getLinearVelocity()
			local grounded = isGrounded(body)
			if grounded and velocityY >= 0 then
				jumpCount = 0
			elseif not grounded and jumpCount == 0 then
				jumpCount = 1
			end

			if input:isJustPressed("jump") and jumpCount < MAX_JUMP then
				velocityY = -JUMP_SPEED
				jumpCount = jumpCount + 1
			end
			velocity.x, velocity.y = direction * PLAYER_SPEED, velocityY
			body:setLinearVelocity(velocity.x, velocity.y)

			local velocityX, currentVelocityY = body:getLinearVelocity()
			local animationName
			if currentVelocityY < -1 then
				animationName = "jump"
			elseif not grounded then
				animationName = "fall"
			elseif math.abs(velocityX) > 1 then
				animationName = "run"
			else
				animationName = "idle"
			end
			local animation = assert(world:getComponent(entity, Components.Animation))
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

return PlayerSystem