local Scene = require("lua.engine.scene.scene")
local mapInfo = require("game.maps.village")
local utils = require("lua.engine.graphics.utils")
local TilemapRender = require("lua.engine.tilemap.tilemaprender")
local RenderPipeline = require("lua.engine.graphics.render_pipeline")
local RenderSystem = require("lua.engine.ecs.systems.renderSystem")
local World = require("lua.engine.ecs.world")
local Components = require("lua.engine.ecs.component")
local MovementSystem = require("lua.engine.ecs.systems.movementSystem")
local PhysicsMovementSystem = require("lua.engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("lua.engine.ecs.systems.physicsSystem")
local PhysicsSyncSystem = require("lua.engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("lua.engine.ecs.systems.collisionSystem")
local PhysicsDebugSystem = require("lua.engine.ecs.systems.physicsDebugSystem")
local PhysicsFactory = require("lua.engine.physics.physics_factory")

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

	local ground = world:createEntity()
	world:addComponent(ground, Components.Transform, { x = 152, y = 104 })
	world:addComponent(ground, Components.RigidBody, { type = "static" })
	world:addComponent(ground, Components.Collider, { shape = "rectangle", width = 304, height = 16 })
	PhysicsFactory.create(world, ground)

	local ground2 = world:createEntity()
	world:addComponent(ground2, Components.Transform, { x = 152, y = 304 })
	world:addComponent(ground2, Components.RigidBody, { type = "static" })
	world:addComponent(ground2, Components.Collider, { shape = "rectangle", width = 604, height = 16 })
	PhysicsFactory.create(world, ground2)

	local image = resourceManager:get(self, "player_idle")
	local frame = love.graphics.newQuad(0, 0, 32, 32, image:getDimensions())
	for index, position in ipairs({ { x = 80, y = 32 }, { x = 200, y = 16 } }) do
		local entity = world:createEntity()
		if index == 1 then
			self.player = entity
		end
		world:addComponent(entity, Components.Transform, { x = position.x, y = position.y })
		world:addComponent(entity, Components.Velocity, { x = index == 1 and 40 or 0, y = 0 })
		world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
		world:addComponent(entity, Components.Collider, { shape = "rectangle", width = 32, height = 32 })
		world:addComponent(entity, Components.Sprite, {
			image = image,
			layer = 40,
			origin = { x = 16, y = 16 },
			animations = { idle = { image = image, frames = { frame } } },
		})
		world:addComponent(entity, Components.Animation, { current = "idle", frame = 1 })
		local body = PhysicsFactory.create(world, entity)
		if entity == self.player then
			body:setFixedRotation(true)
		end
	end
end

function Level01:update(dt)
	local escapeDown = love.keyboard.isDown("escape")
	if escapeDown and not self.escapeDown then
		self.context.sceneManager:push("pause")
	end
	self.escapeDown = escapeDown

	local body = assert(self.world:getComponent(self.player, Components.RigidBody)).body
	local velocity = assert(self.world:getComponent(self.player, Components.Velocity))
	local _, velocityY = body:getLinearVelocity()
	body:setLinearVelocity(assert(velocity.x), assert(velocityY))
	self.world:update(dt)
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
