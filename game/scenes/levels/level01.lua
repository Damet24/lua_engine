local Scene = require("lua.engine.scene.scene")
local mapInfo = require("game.maps.village")
local utils = require("lua.engine.graphics.utils")
local TilemapRender = require("lua.engine.tilemap.tilemaprender")
local RenderPipeline = require("lua.engine.graphics.render_pipeline")
local RenderSystem = require("lua.engine.ecs.systems.renderSystem")
local AnimationSystem = require("lua.engine.ecs.systems.animationSystem")
local World = require("lua.engine.ecs.world")
local Components = require("lua.engine.ecs.component")
local MovementSystem = require("lua.engine.ecs.systems.movementSystem")
local PhysicsMovementSystem = require("lua.engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("lua.engine.ecs.systems.physicsSystem")
local PhysicsSyncSystem = require("lua.engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("lua.engine.ecs.systems.collisionSystem")
local PhysicsDebugSystem = require("lua.engine.ecs.systems.physicsDebugSystem")
local PhysicsFactory = require("lua.engine.physics.physics_factory")

local PLAYER_SPEED = 100
local JUMP_SPEED = 300

local function isGrounded(body)
	for _, contact in ipairs(body:getContacts()) do
		if contact:isTouching() and contact:isEnabled() then
			local first, second = contact:getFixtures()
			if not first:isSensor() and not second:isSensor() then
				local _, normalY = contact:getNormal()
				if (first:getBody() == body and normalY > 0.5) or (second:getBody() == body and normalY < -0.5) then
					return true
				end
			end
		end
	end
	return false
end

local Level01 = {}
Level01.__index = Level01

setmetatable(Level01, {
	__index = Scene,
})

function Level01.new(context)
	local self = Scene.new()

	setmetatable(self, Level01)

	self.context = context

	return self
end

function Level01:onLoad()
	local resourceManager = self.context.resourceManager
	local tilesets = {
		["Terrain (16x16)"] = utils.loadQuads(resourceManager:get(self, "terrain"), 16, 16),
	}
	self.tilemapRender = TilemapRender.new(mapInfo, tilesets)
	self.pipeline = RenderPipeline.new()
	self.world = World.new(0, 640, true)
	local world = self.world
	world:addSystem(AnimationSystem)
	world:addSystem(MovementSystem)
	world:addSystem(PhysicsMovementSystem)
	world:addSystem(PhysicsSystem)
	world:addSystem(PhysicsSyncSystem)
	world:addSystem(CollisionSystem)
	world.events:on("collision_started", function(contact)
		print("collision_started", contact.entityA, contact.entityB)
	end)
	world.events:on("collision_ended", function(contact)
		print("collision_ended", contact.entityA, contact.entityB)
	end)

	for _, layer in ipairs(mapInfo.layers) do
		if layer.type == "objectgroup" and layer.name == "walls" then
			local offsetX = (layer.x or 0) * mapInfo.tilewidth + (layer.offsetx or 0)
			local offsetY = (layer.y or 0) * mapInfo.tileheight + (layer.offsety or 0)
			for _, object in ipairs(layer.objects) do
				assert(object.shape == "rectangle", "walls must contain only rectangles")
				local rotation = math.rad(object.rotation or 0)
				local cos, sin = math.cos(rotation), math.sin(rotation)
				local entity = world:createEntity()
				world:addComponent(entity, Components.Transform, {
					x = offsetX + object.x + cos * object.width / 2 - sin * object.height / 2,
					y = offsetY + object.y + sin * object.width / 2 + cos * object.height / 2,
					rotation = rotation,
				})
				world:addComponent(entity, Components.RigidBody, { type = "static" })
				world:addComponent(entity, Components.Collider, {
					shape = "rectangle",
					width = object.width,
					height = object.height,
				})
				PhysicsFactory.create(world, entity)
			end
		end
	end

	local image = resourceManager:get(self, "player_idle")
	local animations = {
		idle = utils.loadAnimation(image, 32, 32, 0.1),
		run = utils.loadAnimation(resourceManager:get(self, "player_run"), 32, 32, 0.1),
		jump = utils.loadAnimation(resourceManager:get(self, "player_jump"), 32, 32, 0.1),
		fall = utils.loadAnimation(resourceManager:get(self, "player_fall"), 32, 32, 0.1),
	}
	local entity = world:createEntity()
	self.player = entity
	world:addComponent(entity, Components.Transform, { x = 80, y = 32 })
	world:addComponent(entity, Components.Velocity, { x = 0, y = 0 })
	world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
	world:addComponent(entity, Components.Collider, { shape = "rectangle", width = 18, height = 28 })
	world:addComponent(entity, Components.Sprite, {
		image = image,
		layer = 40,
		origin = { x = 16, y = 16 },
		flipH = false,
		animations = animations,
	})
	world:addComponent(
		entity,
		Components.Animation,
		{ current = "idle", frame = 1, timer = 0, playing = true, loop = true }
	)
	local body, fixture = PhysicsFactory.create(world, entity)
	fixture:setFriction(0)
	body:setFixedRotation(true)
end

function Level01:update(dt)
	if self.context.inputManager:isJustPressed("exit") then
		self.context.sceneManager:push("pause")
	end

	local body = assert(self.world:getComponent(self.player, Components.RigidBody)).body
	local velocity = assert(self.world:getComponent(self.player, Components.Velocity))
	local input = self.context.inputManager
	local direction = (input:isDown("move_right") and 1 or 0) - (input:isDown("move_left") and 1 or 0)
	if direction ~= 0 then
		local sprite = assert(self.world:getComponent(self.player, Components.Sprite))
		sprite.flipH = direction < 0
	end
	local _, velocityY = body:getLinearVelocity()
	if input:isJustPressed("jump") and velocityY >= 0 and isGrounded(body) then
		velocityY = -JUMP_SPEED
	end
	velocity.x, velocity.y = direction * PLAYER_SPEED, velocityY
	body:setLinearVelocity(velocity.x, velocity.y)
	self.world:update(dt)

	local velocityX, currentVelocityY = body:getLinearVelocity()
	local animationName
	if currentVelocityY < -1 then
		animationName = "jump"
	elseif not isGrounded(body) then
		animationName = "fall"
	elseif math.abs(velocityX) > 1 then
		animationName = "run"
	else
		animationName = "idle"
	end

	local animation = assert(self.world:getComponent(self.player, Components.Animation))
	if animation.current ~= animationName then
		animation.current = animationName
		animation.frame = 1
		animation.timer = 0
		animation.playing = true
		animation.loop = true
	end
end

function Level01:onDestroy()
	self.context.resourceManager:releaseAll(self)
end

function Level01:draw()
	self.pipeline:clear()
	self.tilemapRender:submit(self.pipeline)
	RenderSystem.submit(self.world, self.pipeline)
	self.pipeline:draw()
	PhysicsDebugSystem.draw(self.world)
end

return Level01
