package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

rawset(love, "load", function()
	local ok, message = xpcall(function()
		local World = require("engine.ecs.world")
		local Components = require("engine.ecs.component")
		local PhysicsFactory = require("engine.physics.physics_factory")
		local MovementSystem = require("engine.ecs.systems.movementSystem")
		local PhysicsMovementSystem = require("engine.ecs.systems.physicsMovementSystem")
		local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
		local PhysicsSyncSystem = require("engine.ecs.systems.physicsSyncSystem")
		local CollisionSystem = require("engine.ecs.systems.collisionSystem")
		local EnemySystem = require("game.ecs.systems.enemySystem")

		local world = World.new(0, 640, true)
		world:addSystem(MovementSystem)
		world:addSystem(PhysicsMovementSystem)
		world:addSystem(PhysicsSystem)
		world:addSystem(PhysicsSyncSystem)
		world:addSystem(CollisionSystem)

		local function createBody(x, y, width, height, bodyType)
			local entity = world:createEntity()
			world:addComponent(entity, Components.Transform, { x = x, y = y })
			world:addComponent(entity, Components.RigidBody, { type = bodyType })
			world:addComponent(entity, Components.Collider, { shape = "rectangle", width = width, height = height })
			return entity, PhysicsFactory.create(world, entity)
		end

		-- The platform extends from x=-160 to x=160, with its top at y=110.
		createBody(0, 120, 320, 20, "static")
		local enemy, body, fixture = createBody(90, 10, 18, 28, "dynamic")
		fixture:setFriction(0)
		body:setFixedRotation(true)
		world:addComponent(enemy, Components.Velocity, { x = 0, y = 0 })
		world:addComponent(enemy, Components.Animation, { current = "fall", frame = 1, timer = 0 })
		world:addSystem(EnemySystem.new(enemy))
		local animation = assert(world:getComponent(enemy, Components.Animation))

		local startX, startY = body:getPosition()
		for _ = 1, 10 do world:update(1 / 60) end
		local x, y = body:getPosition()
		local vx, vy = body:getLinearVelocity()
		assert(x < startX - 5 and math.abs(vx + 60) < 1, "enemy did not move left at the expected speed")
		assert(y > startY and vy > 20, "gravity did not accelerate the enemy downward")
		assert(animation.current == "fall", "airborne enemy must use fall")

		local landed = false
		for _ = 1, 120 do
			world:update(1 / 60)
			if animation.current == "run" then
				landed = true
				break
			end
		end
		assert(landed, "enemy did not land and switch to run")
		local landedX, landedY = body:getPosition()
		assert(math.abs(landedY - 96) < 3, "enemy landed at an unexpected height")
		for _ = 1, 30 do world:update(1 / 60) end
		x, y = body:getPosition()
		assert(x < landedX - 20 and math.abs(y - landedY) < 3, "enemy did not keep running on the platform")
		assert(animation.current == "run", "enemy should remain in run while grounded")

		local fell = false
		for _ = 1, 360 do
			world:update(1 / 60)
			x, y = body:getPosition()
			vx, vy = body:getLinearVelocity()
			if x < -169 and y > landedY + 5 and vy > 20 then
				fell = true
				break
			end
		end
		assert(fell, "enemy did not walk off the left edge and fall under gravity")
		assert(math.abs(vx + 60) < 1, "enemy stopped moving left after leaving the edge")
		assert(animation.current == "fall", "enemy must switch to fall after leaving the edge")
		print("LÖVE enemy physics tests passed")
	end, debug.traceback)
	if not ok then io.stderr:write(message .. "\n") end
	love.event.quit(ok and 0 or 1)
end)
