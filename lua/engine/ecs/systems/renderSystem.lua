local Components = require("lua.engine.ecs.component")

local RenderSystem = {}

function RenderSystem.draw(world)
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
        local layerA = a.sprite.layer or 0
        local layerB = b.sprite.layer or 0

        if layerA == layerB then
            return a.entity < b.entity
        end

        return layerA < layerB
    end)

    for _, renderable in ipairs(renderables) do
        local transform = renderable.transform
        local sprite = renderable.sprite
        local animation = world:getComponent(renderable.entity, Components.Animation)
        local currentAnimation = animation and sprite.animations and sprite.animations[animation.current]
        local frame = currentAnimation and currentAnimation.frames[animation.frame]
        local origin = sprite.origin or {}

        love.graphics.push("all")
        love.graphics.setColor(1, 1, 1, 1)
        if frame then
            love.graphics.draw(currentAnimation.image, frame, transform.x, transform.y, 0, 1, 1, origin.x or 0, origin.y or 0)
        else
            love.graphics.draw(sprite.image, transform.x, transform.y, 0, 1, 1, origin.x or 0, origin.y or 0)
        end
        love.graphics.pop()
    end
end

return RenderSystem
