local PhysicsSystem = {}

function PhysicsSystem.update(world, dt)
	if not world.physics then
		return
	end

	local step = 1 / 60
	world.physicsAccumulator = (world.physicsAccumulator or 0) + dt
	while world.physicsAccumulator >= step do
		world.physics:update(step)
		world.physicsAccumulator = world.physicsAccumulator - step
	end
end

return PhysicsSystem
