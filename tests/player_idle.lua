local drawnImage, drawnQuad
love = {
	graphics = {
		newQuad = function(x, y, width, height, imageWidth, imageHeight)
			return { x = x, y = y, width = width, height = height, imageWidth = imageWidth, imageHeight = imageHeight }
		end,
		push = function() end,
		pop = function() end,
		setColor = function() end,
		draw = function(image, quad) drawnImage, drawnQuad = image, quad end,
	},
	keyboard = { isDown = function() return false end },
}

package.loaded["lua.engine.physics.physics_world"] = { new = function() return {} end }
for _, name in ipairs({ "physicsMovementSystem", "physicsSystem", "physicsSyncSystem", "collisionSystem" }) do
	package.loaded["lua.engine.ecs.systems." .. name] = {}
end
package.loaded["lua.engine.physics.physics_factory"] = {
	create = function(world, entity)
		local body = {
			setFixedRotation = function() end,
			getLinearVelocity = function() return 0, 0 end,
			setLinearVelocity = function() end,
		}
		world:getComponent(entity, "RigidBody").body = body
		return body
	end,
}

local image = { getDimensions = function() return 96, 32 end }
local terrain = { getDimensions = function() return 16, 16 end }
local resources = { get = function(_, _, id) return id == "player_idle" and image or terrain end }
local Level01 = require("game.scenes.levels.level01")
local Components = require("lua.engine.ecs.component")
local RenderSystem = require("lua.engine.ecs.systems.renderSystem")
local level = Level01.new({ resourceManager = resources })
level:onLoad()

local world = level.world
local sprite = assert(world:getComponent(level.player, Components.Sprite))
local state = assert(world:getComponent(level.player, Components.Animation))
local idle = assert(sprite.animations.idle)
assert(#idle.frames == 3 and idle.frameDuration == 0.1)
assert(state.playing and state.loop and state.frame == 1)

local function assertDrawnFrame(frame)
	RenderSystem.drawEntity(world, {
		entity = level.player,
		transform = world:getComponent(level.player, Components.Transform),
		sprite = sprite,
	})
	assert(drawnImage == image and drawnQuad == idle.frames[frame])
end

assertDrawnFrame(1)
level:update(0.1)
assert(state.frame == 2)
assertDrawnFrame(2)
level:update(0.2)
assert(state.frame == 1)
assertDrawnFrame(1)

-- Each entity has its own playback state even though they share the animation frames.
local other = assert(world:getComponent(level.player + 1, Components.Animation))
assert(other ~= state and other.frame == 1)
state.playing = false
level:update(0.1)
assert(state.frame == 1 and other.frame == 2)

other.loop = false
level:update(0.3)
assert(other.frame == 3 and not other.playing)
print("player idle animation tests passed")
