local Components = require("engine.ecs.component")

local AnimationSystem = {}

function AnimationSystem.update(world, dt)
	world:query({
		Components.Sprite,
		Components.Animation,
	}, function(entity, components)
		local sprite = components.Sprite
		local animation = components.Animation

		local currentAnimation = sprite.animations and sprite.animations[animation.current]

		if not currentAnimation or not animation.playing then
			return
		end

		assert(type(currentAnimation.frameDuration) == "number" and currentAnimation.frameDuration > 0, "frameDuration must be positive")
		animation.timer = animation.timer + dt

		while animation.playing and animation.timer >= currentAnimation.frameDuration do
			animation.timer = animation.timer - currentAnimation.frameDuration

			animation.frame = animation.frame + 1

			if animation.frame > #currentAnimation.frames then
				if animation.loop then
					animation.frame = 1
				else
					animation.frame = #currentAnimation.frames
					animation.playing = false
				end
			end
		end
	end)
end

return AnimationSystem
