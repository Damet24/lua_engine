local RenderPipeline = require("engine.graphics.render_pipeline")
local RenderSystem = require("engine.ecs.systems.renderSystem")
local TilemapRender = require("engine.tilemap.tilemaprender")

local drawn = {}
love = { graphics = {
	push = function() end,
	pop = function() end,
	setColor = function() end,
	draw = function(image, quad)
		table.insert(drawn, image == "tilemap" and quad or image)
	end,
} }

local map = {
	width = 1, height = 1, tilewidth = 16, tileheight = 16,
	tilesets = { { name = "terrain", firstgid = 1 } },
	layers = {
		{ type = "tilelayer", data = { 1 }, properties = { layer = 10 } },
		{ type = "tilelayer", data = { 2 }, properties = { layer = 30 } },
		{ type = "tilelayer", data = { 3 }, visible = false },
	},
}
local renderer = TilemapRender.new(map, { terrain = { image = "tilemap", quads = { "ground", "trees", "hidden" } } })

local world = {}
function world:query(_, callback)
	callback(2, { Transform = { x = 0, y = 0 }, Sprite = { image = "enemy", layer = 20 } })
	callback(1, { Transform = { x = 0, y = 0 }, Sprite = { image = "player", layer = 20 } })
end
function world:getComponent() return nil end

local pipeline = RenderPipeline.new()
renderer:submit(pipeline)
RenderSystem.submit(world, pipeline)
pipeline:draw()
assert(table.concat(drawn, ",") == "ground,player,enemy,trees")

pipeline:clear()
drawn = {}
pipeline:add(0, function() table.insert(drawn, "first") end)
pipeline:add(0, function() table.insert(drawn, "second") end)
pipeline:draw()
assert(table.concat(drawn, ",") == "first,second")

drawn = {}
renderer:render()
assert(table.concat(drawn, ",") == "ground,trees")
drawn = {}
RenderSystem.draw(world)
assert(table.concat(drawn, ",") == "player,enemy")

pipeline:clear()
drawn = {}
local defaultMap = {
	width = 1, height = 1, tilewidth = 16, tileheight = 16,
	tilesets = map.tilesets,
	layers = {
		{ type = "objectgroup" },
		{ type = "tilelayer", data = { 1 } },
	},
}
TilemapRender.new(defaultMap, renderer.tilesets):submit(pipeline)
pipeline:add(1, function() table.insert(drawn, "before") end)
pipeline:draw()
assert(table.concat(drawn, ",") == "before,ground")

pipeline:clear()
drawn = {}
local animatedWorld = {}
function animatedWorld:query(_, callback)
	callback(1, {
		Transform = { x = 0, y = 0 },
		Sprite = { image = "static", animations = { walk = { image = "animated", frames = { "frame" } } } },
	})
end
function animatedWorld:getComponent() return { current = "walk", frame = 1 } end
RenderSystem.submit(animatedWorld, pipeline)
pipeline:draw()
assert(table.concat(drawn, ",") == "animated")

print("render pipeline tests passed")