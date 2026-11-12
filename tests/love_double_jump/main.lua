package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

local World = require("engine.ecs.world")
local Components = require("engine.ecs.component")
local PhysicsFactory = require("engine.physics.physics_factory")
local PhysicsMovementSystem = require("engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local CollisionSystem = require("engine.ecs.systems.collisionSystem")
local PlayerSystem = require("game.ecs.systems.playerSystem")

rawset(love, "load", function()
	local ok, message = xpcall(function()
		local world = World.new(0, 640, true)
		world:addSystem(PhysicsMovementSystem)
		world:addSystem(PhysicsSystem)
		world:addSystem(CollisionSystem)
		local function createBody(x, y, width, height, bodyType)
			local entity = world:createEntity()
			world:addComponent(entity, Components.Transform, { x = x, y = y })
			world:addComponent(entity, Components.RigidBody, { type = bodyType })
			world:addComponent(entity, Components.Collider, { shape = "rectangle", width = width, height = height })
			return entity, PhysicsFactory.create(world, entity)
		end
		createBody(100, 120, 200, 20, "static")
		local player, body = createBody(100, 70, 18, 28, "dynamic")
		body:setFixedRotation(true)
		world:addComponent(player, Components.Velocity, { x = 0, y = 0 })
		world:addComponent(player, Components.Sprite, { flipH = false })
		world:addComponent(player, Components.Animation, { current = "idle", frame = 1, timer = 0 })
		local input = { jump = false }
		function input:isDown() return false end
		function input:isJustPressed(action) return action == "jump" and self.jump end
		world:addSystem(PlayerSystem.new(input, player))
		for _ = 1, 120 do world:update(1 / 60) end
		input.jump = true
		world:update(1 / 60)
		local _, vertical = body:getLinearVelocity()
		assert(vertical < -250, "first jump failed")
		input.jump = false
		for _ = 1, 12 do world:update(1 / 60) end
		input.jump = true
		world:update(1 / 60)
		_, vertical = body:getLinearVelocity()
		assert(vertical < -250, "second jump failed")
		input.jump = false
		world:update(1 / 60)
		input.jump = true
		world:update(1 / 60)
		_, vertical = body:getLinearVelocity()
		assert(vertical > -295, "third jump should be blocked")
		input.jump = false
		for _ = 1, 180 do world:update(1 / 60) end
		input.jump = true
		world:update(1 / 60)
		_, vertical = body:getLinearVelocity()
		assert(vertical < -250, "jump after landing failed")
		print("LÖVE double jump tests passed")
	end, debug.traceback)
	if not ok then io.stderr:write(message .. "\n") end
	love.event.quit(ok and 0 or 1)
end)