local Scene = require("engine.scene.scene")
local utils = require("engine.graphics.utils")
local TilemapRender = require("engine.tilemap.tilemaprender")
local RenderPipeline = require("engine.graphics.render_pipeline")
local CameraManager = require("engine.camera.cameraManager")
local RenderSystem = require("engine.ecs.systems.renderSystem")
local AnimationSystem = require("engine.ecs.systems.animationSystem")
local World = require("engine.ecs.world")
local Components = require("engine.ecs.component")
local MovementSystem = require("engine.ecs.systems.movementSystem")
local PhysicsMovementSystem = require("engine.ecs.systems.physicsMovementSystem")
local PhysicsSystem = require("engine.ecs.systems.physicsSystem")
local PhysicsSyncSystem = require("engine.ecs.systems.physicsSyncSystem")
local CollisionSystem = require("engine.ecs.systems.collisionSystem")
local PhysicsDebugSystem = require("engine.ecs.systems.physicsDebugSystem")
local PhysicsFactory = require("engine.physics.physics_factory")
local PlayerSystem = require("game.ecs.systems.playerSystem")
local EnemySystem = require("game.ecs.systems.enemySystem")

local function findPlayerSpawn(map)
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.name == "objects" then
            for _, object in ipairs(layer.objects) do
                if object.name == "playerSpawn" and object.shape == "point" then
                    return {
                        x = object.x + (layer.offsetx or 0),
                        y = object.y + (layer.offsety or 0),
                    }
                end
            end
        end
    end

    return nil
end

local function limitAxis(position, mapSize, halfView)
	if mapSize <= halfView * 2 then
		return mapSize / 2
	end
	return math.max(halfView, math.min(position, mapSize - halfView))
end

local function followWithinMap(camera, playerX, playerY, map)
	local _, _, width, height = camera:getViewport()
	local zoom = camera:getZoom()
	local halfWidth, halfHeight = width / (2 * zoom), height / (2 * zoom)
	local mapWidth = map.width * map.tilewidth
	local mapHeight = 240
	camera:setPosition(limitAxis(playerX, mapWidth, halfWidth), limitAxis(playerY, mapHeight, halfHeight))
end

local function createPlayer(world, context, spawn, image, animations)
    local entity = world:createEntity()
    world:addComponent(entity, Components.Transform, { x = spawn.x, y = spawn.y })
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
    world:addSystem(PlayerSystem.new(context.inputManager, entity, context.audioManager))
    local transform = assert(world:getComponent(entity, Components.Transform))

    return entity, transform
end

local function createEnemy(world, spawn, image, animations)
	local entity = world:createEntity()
	world:addComponent(entity, Components.Transform, { x = spawn.x, y = spawn.y })
	world:addComponent(entity, Components.Velocity, { x = 0, y = 0 })
	world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
	world:addComponent(entity, Components.Collider, { shape = "rectangle", width = 18, height = 28 })
	world:addComponent(entity, Components.Sprite, {
		image = image,
		layer = 40,
		origin = { x = 16, y = 16 },
		flipH = true,
		animations = animations,
	})
	world:addComponent(entity, Components.Animation, { current = "fall", frame = 1, timer = 0, playing = true, loop = true })
	local body, fixture = PhysicsFactory.create(world, entity)
	fixture:setFriction(0)
	body:setFixedRotation(true)
	world:addSystem(EnemySystem.new(entity))
end

local function drawStaticBackground(image, viewport, indexY)
	local screenWidth, screenHeight = viewport.getViewportDimensions()
	local tileW, tileH = 64, 64
    local offsetY = indexY % tileH

	for y = -tileH, screenHeight, tileH do
		for x = 0, screenWidth, tileW do
			love.graphics.draw(image, x, y + offsetY)
		end
	end
end


local Level = {}
Level.__index = Level

setmetatable(Level, {
	__index = Scene,
})

function Level.new(context, config)
	assert(type(config) == "table" and type(config.map) == "table", "level config requires a map")
	local self = Scene.new()

	setmetatable(self, Level)

	self.context = context
	self.map = config.map
	self.enemySpawns = config.enemySpawns or {}
	self.spawn = findPlayerSpawn(config.map) or { x = 80, y = 32 }
	self.tilesets = config.tilesets or {
		["Terrain (16x16)"] = { resource = "terrain", tilewidth = 16, tileheight = 16 },
	}
	self.leftWallEntity = nil
	self.leftWallHalfWidth = 0
    self.leftWallMargin = 0
    self.background = config.background

	self.backgroundIndexAnimation = 0

	return self
end


function Level:onLoad()
    local resourceManager = self.context.resourceManager
    self.backgroundImage = resourceManager:get(self, self.background)
	local width, height = self.context.viewport.getViewportDimensions()
	self.cameraManager = CameraManager.new()
	self.cameraManager:add("gameplay", {
		x = width / 2, y = height / 2,
		viewport = { width = width, height = height },
	})
	self.cameraManager:setActive("gameplay")
	local tilesets = {}
	for name, definition in pairs(self.tilesets) do
		tilesets[name] = utils.loadQuads(resourceManager:get(self, definition.resource), definition.tilewidth, definition.tileheight)
	end
	self.tilemapRender = TilemapRender.new(self.map, tilesets)
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

	for _, layer in ipairs(self.map.layers) do
		if layer.type == "objectgroup" and layer.name == "walls" then
			local offsetX = (layer.x or 0) * self.map.tilewidth + (layer.offsetx or 0)
			local offsetY = (layer.y or 0) * self.map.tileheight + (layer.offsety or 0)
			for _, object in ipairs(layer.objects) do
				assert(object.shape == "rectangle", "walls must contain only rectangles")
				local rotation = math.rad(object.rotation or 0)
				local cos, sin = math.cos(rotation), math.sin(rotation)
				local entity = world:createEntity()
				local wallX = offsetX + object.x + cos * object.width / 2 - sin * object.height / 2
				local wallY = offsetY + object.y + sin * object.width / 2 + cos * object.height / 2
				world:addComponent(entity, Components.Transform, {
					x = wallX,
					y = wallY,
					rotation = rotation,
				})
				world:addComponent(entity, Components.RigidBody, { type = "static" })
				world:addComponent(entity, Components.Collider, {
					shape = "rectangle",
					width = object.width,
					height = object.height,
				})
				PhysicsFactory.create(world, entity)

				if object.name == "leftWall" then
					self.leftWallEntity = entity
					self.leftWallHalfWidth = object.width / 2
					self.leftWallMargin = -16
				end
			end
		end
	end

	local image = resourceManager:get(self, "player_idle")
	local animations = {
		idle = utils.loadAnimation(image, 32, 32, 0.1),
		run = utils.loadAnimation(resourceManager:get(self, "player_run"), 32, 32, 0.05),
		jump = utils.loadAnimation(resourceManager:get(self, "player_jump"), 32, 32, 0.1),
		fall = utils.loadAnimation(resourceManager:get(self, "player_fall"), 32, 32, 0.1),
	}

	local player, transform = createPlayer(self.world, self.context, self.spawn, image, animations)
	self.player = player

	if #self.enemySpawns > 0 then
		local enemyImage = resourceManager:get(self, "mask_dude_run")
		local enemyAnimations = {
			run = utils.loadAnimation(enemyImage, 32, 32, 0.05),
			fall = utils.loadAnimation(resourceManager:get(self, "mask_dude_fall"), 32, 32, 0.1),
		}
		for _, spawn in ipairs(self.enemySpawns) do
			createEnemy(world, spawn, enemyImage, enemyAnimations)
		end
	end

    followWithinMap(assert(self.cameraManager:getActive()), transform.x, transform.y, self.map)
    local camX = select(1, assert(self.cameraManager:getActive()):getPosition())
    self.cameraDistanceTraveled = camX

    self.context.audioManager:playMusic("music")
end

function Level:update(dt)
	if self.context.inputManager:isJustPressed("exit") then
		self.context.sceneManager:push("pause")
	end
	self.world:update(dt)

	local body = assert(self.world:getComponent(self.player, Components.RigidBody)).body
	local playerX, playerY = body:getPosition()

	local camera = assert(self.cameraManager:getActive())
	local _, _, width, height = camera:getViewport()
	local zoom = camera:getZoom()
	local halfWidth, halfHeight = width / (2 * zoom), height / (2 * zoom)

	local mapWidth = self.map.width * self.map.tilewidth
	local mapHeight = 240

	-- Posición objetivo normal (siguiendo al jugador y limitada por mapa)
	local targetX = limitAxis(playerX, mapWidth, halfWidth)
	local targetY = limitAxis(playerY, mapHeight, halfHeight)

	-- Bloqueo estilo Mario: la cámara nunca retrocede en X
	self.cameraDistanceTraveled = math.max(self.cameraDistanceTraveled, targetX)

	camera:setPosition(self.cameraDistanceTraveled, targetY)

	if self.leftWallEntity then
		local leftWallTransform = self.world:getComponent(self.leftWallEntity, Components.Transform)
		local leftWallBody = self.world:getComponent(self.leftWallEntity, Components.RigidBody)
		if leftWallTransform and leftWallBody and leftWallBody.body then
			local leftEdgeX = self.cameraDistanceTraveled - halfWidth
			local lockedX = leftEdgeX + self.leftWallHalfWidth + self.leftWallMargin
			leftWallTransform.x = lockedX
			leftWallBody.body:setPosition(lockedX, leftWallTransform.y)
		end
	end

	self.backgroundIndexAnimation = (self.backgroundIndexAnimation + 4 * dt) % 64
end

function Level:onDestroy()
	self.cameraManager = nil
	self.context.resourceManager:releaseAll(self)
end

function Level:draw()
	if self.backgroundImage then
		drawStaticBackground(self.backgroundImage, self.context.viewport, self.backgroundIndexAnimation)
	end

	self.pipeline:clear()
	self.tilemapRender:submit(self.pipeline)
	RenderSystem.submit(self.world, self.pipeline)
	self.cameraManager:getActive():draw(function()
		self.pipeline:draw()
		PhysicsDebugSystem.draw(self.world)
    end)
end


return Level
