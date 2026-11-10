local Components = require("lua.engine.ecs.component")

local AnimationSystem = {}

function AnimationSystem.update(world, dt)
	world:query({
		Components.Sprite,
		Components.Animation,
	}, function(entity, components)
		local sprite = components.Sprite
		local animation = components.Animation

		local currentAnimation = sprite.animations[animation.current]

		if not currentAnimation or not animation.playing then
			return
		end

		animation.timer = animation.timer + dt

		if animation.timer >= currentAnimation.frameDuration then
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
