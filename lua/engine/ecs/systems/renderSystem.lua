local Components = require("lua.engine.ecs.component")

local RenderSystem = {}

function RenderSystem.draw(world)
	world:query({
		Components.Transform,
		Components.Sprite,
	}, function(entity, components)
		local transform = components.Transform
		local sprite = components.Sprite
		


		local origin = sprite.origin or {}
		local originX = origin.x or 0
		local originY = origin.y or 0

		love.graphics.push()

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(sprite.image, transform.x, transform.y, 0 ,1, 1, originX, originY)

		love.graphics.pop()
	end)
end

return RenderSystem
