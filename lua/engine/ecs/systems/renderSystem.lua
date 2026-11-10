local Components = require("lua.engine.ecs.component")

local RenderSystem = {}

function RenderSystem.draw(world)
	world:query({
		Components.Transform,
		Components.Sprite,
		Components.Animation,
	}, function(entity, components)
		local transform = components.Transform
		local sprite = components.Sprite
		local animation = components.Animation

		local currentAnimation = sprite.animations[animation.current]

		if not currentAnimation then
			return
		end

		local current = sprite.animations[animation.current]

		love.graphics.draw(current.image, current.frames[animation.frame], transform.x, transform.y)
	end)
end

return RenderSystem
