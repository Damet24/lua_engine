SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720

local mapInfo = require("game.maps.village")
local utils = require("lua.engine.graphics.utils")
local TilemapRender = require("lua.engine.tilemap.tilemaprender")
local tilesets
local tilemapRender

function love.load()
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, { vsync = true, fullscreen = false })

	tilesets = {
		["Terrain (16x16)"] = utils.loadQuads("game/assets/images/Terrain/Terrain (16x16).png", 16, 16),
	}
	tilemapRender = TilemapRender.new(mapInfo, tilesets)
end

function love.update(dt) end

function love.draw()
	tilemapRender:render()
end
