local RenderSystem = require("lua.engine.ecs.systems.renderSystem")

local drawn
love = { graphics = {
	push = function() end,
	pop = function() end,
	setColor = function() end,
	draw = function(...) drawn = { ... } end,
} }

local animation
local world = { getComponent = function() return animation end }
local sprite = {
	image = "static",
	origin = { x = 7, y = 11 },
	animations = { idle = { image = "animated", frames = { "quad" } } },
}
local renderable = { entity = 1, transform = { x = 25, y = 30, rotation = 0.5 }, sprite = sprite }

local function check(animated, flipH, flipV, expectedX, expectedY)
	sprite.flipH, sprite.flipV = flipH, flipV
	animation = animated and { current = "idle", frame = 1 } or nil
	RenderSystem.drawEntity(world, renderable)
	local offset = animated and 1 or 0
	assert(drawn[1] == (animated and "animated" or "static"))
	if animated then assert(drawn[2] == "quad") end
	assert(drawn[2 + offset] == 25 and drawn[3 + offset] == 30 and drawn[4 + offset] == 0.5)
	assert(drawn[5 + offset] == expectedX and drawn[6 + offset] == expectedY)
	assert(drawn[7 + offset] == 7 and drawn[8 + offset] == 11)
end

for _, animated in ipairs({ false, true }) do
	check(animated, nil, nil, 1, 1)
	check(animated, true, false, -1, 1)
	check(animated, false, true, 1, -1)
	check(animated, true, true, -1, -1)
end

-- A missing animation frame uses the same flip flags on the static image.
animation = { current = "idle", frame = 2 }
RenderSystem.drawEntity(world, renderable)
assert(drawn[1] == "static" and drawn[5] == -1 and drawn[6] == -1)
print("sprite flip tests passed")
