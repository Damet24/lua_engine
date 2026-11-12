local PhysicsWorld = { PIXELS_PER_METER = 64 }

function PhysicsWorld.new(gravityX, gravityY, sleeping)
	love.physics.setMeter(PhysicsWorld.PIXELS_PER_METER)
	return love.physics.newWorld(gravityX or 0, gravityY or 0, sleeping or false)
end

return PhysicsWorld