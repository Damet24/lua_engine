local Components = require("lua.engine.ecs.component")
local RenderPipeline = require("lua.engine.graphics.render_pipeline")

local RenderSystem = {}

function RenderSystem.drawEntity(world, renderable)
	local transform = renderable.transform
	local sprite = renderable.sprite
	local animation = world:getComponent(renderable.entity, Components.Animation)
	local currentAnimation = animation and sprite.animations and sprite.animations[animation.current]
	local frame = currentAnimation and currentAnimation.frames[animation.frame]
	local origin = sprite.origin or {}

	love.graphics.push("all")
	love.graphics.setColor(1, 1, 1, 1)
	if frame then
		love.graphics.draw(
			currentAnimation.image,
			frame,
			transform.x,
			transform.y,
			0,
			1,
			1,
			origin.x or 0,
			origin.y or 0
		)
	else
		love.graphics.draw(sprite.image, transform.x, transform.y, 0, 1, 1, origin.x or 0, origin.y or 0)
	end
	love.graphics.pop()
end

function RenderSystem.submit(world, pipeline)
	local renderables = {}

	world:query({
		Components.Transform,
		Components.Sprite,
	}, function(entity, components)
		table.insert(renderables, {
			entity = entity,
			transform = components.Transform,
			sprite = components.Sprite,
		})
	end)

	table.sort(renderables, function(a, b)
		return a.entity < b.entity
	end)

	for _, renderable in ipairs(renderables) do
		pipeline:add(renderable.sprite.layer, function()
			RenderSystem.drawEntity(world, renderable)
		end)
	end
end

function RenderSystem.draw(world)
	local pipeline = RenderPipeline.new()
	RenderSystem.submit(world, pipeline)
	pipeline:draw()
end

return RenderSystem
