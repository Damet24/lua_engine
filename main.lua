local World = require("lua.engine.ecs.world")
local Movement = require("lua.engine.ecs.systems.movementSystem")
local Animation = require("lua.engine.ecs.systems.animationSystem")
local Render = require("lua.engine.ecs.systems.renderSystem")
local Physics = require("lua.engine.ecs.systems.physicsSystem")
local PhysicsSync = require("lua.engine.ecs.systems.physicsSyncSystem")
local Collision = require("lua.engine.ecs.systems.collisionSystem")
local Components = require("lua.engine.ecs.component")
local Debug = require("lua.engine.ecs.systems.physicsDebugSystem")

local world

local function loadAnimation(path, frameWidth, frameHeight, frameDuration)
	local image = love.graphics.newImage(path)
	local width, height = image:getDimensions()

	local frames = {}

	for y = 0, height - frameHeight, frameHeight do
		for x = 0, width - frameWidth, frameWidth do
			frames[#frames + 1] = love.graphics.newQuad(x, y, frameWidth, frameHeight, width, height)
		end
	end

	return {
		image = image,
		frames = frames,
		frameDuration = frameDuration,
	}
end

function love.load()
	world = World.new()

	world:addSystem(Movement)
	world:addSystem(Animation)
	world:addSystem(Render)

	local player = world:createEntity()
	local playerSprite = {
		origin = { x = 16, y = 16 },
		image = love.graphics.newImage("game/assets/images/Main Characters/Mask Dude/Idle (32x32).png"),
		layer = 1,
		animations = {
			idle = loadAnimation("game/assets/images/Main Characters/Mask Dude/Idle (32x32).png", 32, 32, 0.05),
			run = loadAnimation("game/assets/images/Main Characters/Mask Dude/Run (32x32).png", 32, 32, 0.15),
		},
	}

	local x = 100
	local y = 200


	world:addComponent(player, Components.Transform, { x, y, rotation = 0 })
	world:addComponent(player, Components.Sprite, playerSprite)
	world:addComponent(player, Components.Animation, {
		current = "idle",
		frame = 1,
		timer = 0,
		playing = true,
		loop = true,
	})

end

function love.update(dt)
	world:update(dt)
end

function love.draw()
	world:draw()
end
