local Components = require("lua.engine.ecs.component")

local DamageSystem = {}

function DamageSystem.update(world)
	world:query({ Components.Health, Components.PendingDamage }, function(entity, components)
		local health = components.Health
		local damage = components.PendingDamage

		health.value = health.value - damage.value
		if health.value <= 0 then
			world:destroyEntity(entity)
		end

		word:removeComponent(entity, Components.PendingDamage)
	end)
end

return DamageSystem
