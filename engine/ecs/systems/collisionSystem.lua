local CollisionSystem = {}

function CollisionSystem.init(world)
	world.pendingContacts = {}
	world.physics:setCallbacks(function(first, second)
		table.insert(world.pendingContacts, { name = "collision_started", entityA = first:getUserData(), entityB = second:getUserData() })
	end, function(first, second)
		table.insert(world.pendingContacts, { name = "collision_ended", entityA = first:getUserData(), entityB = second:getUserData() })
	end)
end

function CollisionSystem.update(world)
	local contacts = world.pendingContacts or {}
	world.pendingContacts = {}
	for _, contact in ipairs(contacts) do
		world.events:emit(contact.name, { entityA = contact.entityA, entityB = contact.entityB })
	end
end

return CollisionSystem
