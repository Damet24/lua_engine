SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720

local mapInfo = require("game.maps.village")
local utils = require("lua.engine.graphics.utils")
local TilemapRender = require("lua.engine.tilemap.tilemaprender")
local RenderPipeline = require("lua.engine.graphics.render_pipeline")
local RenderSystem = require("lua.engine.ecs.systems.renderSystem")
local World = require("lua.engine.ecs.world")
local Components = require("lua.engine.ecs.component")
local MovementSystem = require("lua.engine.ecs.systems.movementSystem")
local tilesets
local tilemapRender
local pipeline = RenderPipeline.new()
local world

function love.load()
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, { vsync = true, fullscreen = false })

	tilesets = {
		["Terrain (16x16)"] = utils.loadQuads("game/assets/images/Terrain/Terrain (16x16).png", 16, 16),
	}
	tilemapRender = TilemapRender.new(mapInfo, tilesets)

	world = World.new()
	world:addSystem(MovementSystem)
	local player = world:createEntity()
	local image = love.graphics.newImage("game/assets/images/Main Characters/Pink Man/Idle (32x32).png")
	local frame = love.graphics.newQuad(0, 0, 32, 32, image:getDimensions())
	world:addComponent(player, Components.Transform, { x = 160, y = 80 })
	world:addComponent(player, Components.Velocity, { x = 160, y = 80 })
	world:addComponent(player, Components.Sprite, {
		image = image,
		layer = 40,
		animations = { idle = { image = image, frames = { frame } } },
	})
	world:addComponent(player, Components.Animation, { current = "idle", frame = 1 })
end

function love.update(dt) end

function love.draw()
	pipeline:clear()
	tilemapRender:submit(pipeline)
	RenderSystem.submit(world, pipeline)
	pipeline:draw()
end
