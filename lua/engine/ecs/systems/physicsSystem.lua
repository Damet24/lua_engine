local PhysicsSystem = {}

function PhysicsSystem.update(world, dt)
	if not world.physics then
		return
	end

	world.physics:update(dt)
end

return PhysicsSystem
