package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

local World = require("lua.engine.ecs.world")
local Components = require("lua.engine.ecs.component")
local Factory = require("lua.engine.physics.physics_factory")
local MovementSystem = require("lua.engine.ecs.systems.movementSystem")
local PhysicsMovementSystem = require("lua.engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("lua.engine.ecs.systems.physicsSystem")
local PhysicsSyncSystem = require("lua.engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("lua.engine.ecs.systems.collisionSystem")

function love.run()
	local world = World.new(0, 640, true)
	world:addSystem(MovementSystem)
	world:addSystem(PhysicsMovementSystem)
	world:addSystem(PhysicsSystem)
	world:addSystem(PhysicsSyncSystem)
	world:addSystem(CollisionSystem)

	local function makeEntity(bodyType, x, y, sensor)
		local entity = world:createEntity()
		world:addComponent(entity, Components.Transform, { x = x, y = y, rotation = 0 })
		world:addComponent(entity, Components.RigidBody, { type = bodyType })
		world:addComponent(entity, Components.Collider, { shape = "rectangle", width = 32, height = 32, sensor = sensor })
		return entity, Factory.create(world, entity)
	end

	local floor = makeEntity("static", 0, 100, false)
	local player, body = makeEntity("dynamic", 0, 0, false)
	local sensor, sensorBody, sensorFixture = makeEntity("kinematic", 0, 30, true)
	assert(sensorBody:getType() == "kinematic" and sensorFixture:isSensor())
	world:addComponent(player, Components.Velocity, { x = 0, y = 0 })
	local started, ended = {}, {}
	world.events:on("collision_started", function(contact)
		assert(not world.physics:isLocked())
		started[#started + 1] = contact
	end)
	world.events:on("collision_ended", function(contact) ended[#ended + 1] = contact end)
	for step = 1, 120 do world:update(1 / 60) end
	local transform = assert(world:getComponent(player, Components.Transform))
	assert(transform.y > 0 and math.abs(transform.y - body:getY()) < 0.001)
	assert(transform.y < 100 and #started >= 2 and #ended >= 1)
	assert((started[1].entityA == player and started[1].entityB == sensor) or (started[1].entityB == player and started[1].entityA == sensor))
	assert(floor and sensor)
	local velocity = world:getComponent(player, Components.Velocity)
	velocity.x = 100
	world:update(1 / 60)
	local velocityX = body:getLinearVelocity()
	assert(velocityX > 0)
	body:setLinearVelocity(40, 0)
	world:update(1 / 60)
	velocityX = body:getLinearVelocity()
	assert(velocityX < 100)
	world:destroyEntity(player)
	world:update(1 / 60)
	assert(body:isDestroyed() and not world.entities[player])
	print("Box2D integration tests passed")
	return function() return 0 end
end