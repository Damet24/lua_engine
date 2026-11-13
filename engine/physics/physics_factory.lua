local Components = require("engine.ecs.component")

local PhysicsFactory = {}

function PhysicsFactory.create(world, entity)
	local transform = assert(world:getComponent(entity, Components.Transform), "Transform required")
	local rigidBody = assert(world:getComponent(entity, Components.RigidBody), "RigidBody required")
	local collider = assert(world:getComponent(entity, Components.Collider), "Collider required")
	assert(not rigidBody.body, "body already exists")
	assert(collider.shape == "rectangle", "only rectangle colliders are supported")
	assert(collider.width and collider.width > 0 and collider.height and collider.height > 0, "invalid collider dimensions")

	local shape = love.physics.newRectangleShape(collider.offsetX or 0, collider.offsetY or 0, collider.width, collider.height)
	local body = love.physics.newBody(world.physics, transform.x, transform.y, rigidBody.type or "dynamic")
	body:setAngle(transform.rotation or 0)
	local fixture = love.physics.newFixture(body, shape, collider.density or 1)
	fixture:setSensor(collider.sensor or false)
	fixture:setUserData(entity)
	rigidBody.body = body
	return body, fixture
end

return PhysicsFactory
