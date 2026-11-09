local Components = require("lua.engine.ecs.component")

local DamageSystem = {}

function DamageSystem.update(world)
	world:query({ Components.Health, Components.PendingDamage }, function(entity, components)
		local health = components.Health
		local damage = components.PendingDamage

		health.value = health.value - damage.value
		if health.value <= 0 then
			world.events:emit("entity_died", {
				entity = entity,
			})
			world:destroyEntity(entity)
		end

		world:removeComponent(entity, Components.PendingDamage)
	end)
end

return DamageSystem
