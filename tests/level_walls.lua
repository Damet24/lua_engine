love = {
	graphics = { newQuad = function(...) return { ... } end },
	physics = {
		newRectangleShape = function(x, y, width, height)
			return { x = x, y = y, width = width, height = height }
		end,
		newBody = function(_, x, y, bodyType)
			return {
				x = x, y = y, type = bodyType,
				setAngle = function(self, angle) self.angle = angle end,
				setFixedRotation = function() end,
			}
		end,
		newFixture = function(body, shape)
			body.shape = shape
			return { setSensor = function() end, setUserData = function() end, setFriction = function() end }
		end,
	},
}
package.loaded["lua.engine.physics.physics_world"] = { new = function() return {} end }
package.loaded["lua.engine.ecs.systems.collisionSystem"] = {}

local map = require("game.maps.village")
local Level01 = require("game.scenes.levels.level01")
local Components = require("lua.engine.ecs.component")
local image = { getDimensions = function() return 32, 32 end }
local resources = { get = function() return image end }
local function loadLevel()
	local level = Level01.new({ resourceManager = resources, viewport = {
		getViewportDimensions = function() return 400, 300 end,
	} })
	level:onLoad()
	return level
end

local walls
for _, layer in ipairs(map.layers) do
	if layer.type == "objectgroup" and layer.name == "walls" then walls = layer end
end
assert(walls and #walls.objects > 0)
local level = loadLevel()
assert(level.player == #walls.objects + 1)
for index, object in ipairs(walls.objects) do
	local transform = assert(level.world:getComponent(index, Components.Transform))
	local collider = assert(level.world:getComponent(index, Components.Collider))
	local rigidBody = assert(level.world:getComponent(index, Components.RigidBody))
	assert(transform.x == object.x + object.width / 2 and transform.y == object.y + object.height / 2)
	assert(collider.width == object.width and collider.height == object.height)
	assert(rigidBody.type == "static" and rigidBody.body.type == "static")
	assert(rigidBody.body.x == transform.x and rigidBody.body.y == transform.y)
	assert(rigidBody.body.shape.width == collider.width and rigidBody.body.shape.height == collider.height)
end

-- Tiled rotates rectangles around their top-left corner, not their center.
walls.x, walls.y, walls.offsetx, walls.offsety = 1, 2, 3, 4
walls.objects = { { shape = "rectangle", x = 10, y = 20, width = 40, height = 10, rotation = 90 } }
map.layers[#map.layers + 1] = { type = "objectgroup", name = "other", objects = { { shape = "ellipse" } } }
level = loadLevel()
local transform = assert(level.world:getComponent(1, Components.Transform))
local body = assert(level.world:getComponent(1, Components.RigidBody)).body
assert(math.abs(transform.x - 24) < 0.00001 and math.abs(transform.y - 76) < 0.00001)
assert(math.abs(transform.rotation - math.pi / 2) < 0.00001 and body.angle == transform.rotation)
assert(level.player == 2)

walls.objects[1].shape = "ellipse"
local success, message = pcall(loadLevel)
assert(not success and tostring(message):find("walls must contain only rectangles", 1, true))
print("level walls tests passed")
