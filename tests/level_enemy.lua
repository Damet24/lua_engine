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
				setFixedRotation = function(self, fixed) self.fixedRotation = fixed end,
			}
		end,
		newFixture = function(body, shape)
			body.shape = shape
			return { setSensor = function() end, setUserData = function() end, setFriction = function() end }
		end,
	},
}
package.loaded["engine.physics.physics_world"] = { new = function() return {} end }
package.loaded["engine.ecs.systems.collisionSystem"] = {}

local Level = require("game.scenes.levels.level")
local Level01 = require("game.scenes.levels.level01")
local Components = require("engine.ecs.component")
local requested = {}
local resources = {
	get = function(_, _, id)
		requested[id] = true
		return { getDimensions = function() return id == "mask_dude_run" and 384 or 32, 32 end }
	end,
}
local context = {
	resourceManager = resources,
	viewport = { getViewportDimensions = function() return 320, 240 end },
}

local level = Level01.new(context)
level:onLoad()
local enemy = level.player + 1
local transform = assert(level.world:getComponent(enemy, Components.Transform))
local rigidBody = assert(level.world:getComponent(enemy, Components.RigidBody))
local collider = assert(level.world:getComponent(enemy, Components.Collider))
local sprite = assert(level.world:getComponent(enemy, Components.Sprite))
local animation = assert(level.world:getComponent(enemy, Components.Animation))
assert(transform.x == 384 and transform.y == 192)
assert(rigidBody.type == "dynamic" and rigidBody.body.fixedRotation)
assert(collider.width == 18 and collider.height == 28 and sprite.flipH)
assert(requested.mask_dude_run and requested.mask_dude_fall)
assert(#sprite.animations.run.frames == 12 and #sprite.animations.fall.frames == 1)
assert(animation.current == "fall" and animation.playing)

requested = {}
local empty = Level.new(context, {
	map = { width = 20, height = 15, tilewidth = 16, tileheight = 16, layers = {} },
	background = "background_blue",
})
empty:onLoad()
assert(empty.world.nextEntityId == 1, "levels without enemy spawns must only create the player")
assert(not requested.mask_dude_run and not requested.mask_dude_fall)
print("level enemy tests passed")
