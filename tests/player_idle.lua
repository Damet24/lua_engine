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
for _, name in ipairs({ "physicsSystem", "physicsSyncSystem", "collisionSystem" }) do
	package.loaded["lua.engine.ecs.systems." .. name] = {}
end
package.loaded["lua.engine.physics.physics_factory"] = {
	create = function(world, entity)
		local body = {
			velocityX = 0, velocityY = 0,
			contacts = {},
			setFixedRotation = function() end,
			getType = function() return world:getComponent(entity, "RigidBody").type end,
			getContacts = function(self) return self.contacts end,
			getLinearVelocity = function(self) return self.velocityX, self.velocityY end,
			setLinearVelocity = function(self, x, y) self.velocityX, self.velocityY = x, y end,
		}
		world:getComponent(entity, "RigidBody").body = body
		return body, { setFriction = function() end }
	end,
}

local image = { getDimensions = function() return 96, 32 end }
local terrain = { getDimensions = function() return 16, 16 end }
local images = {
	player_idle = image,
	player_run = { getDimensions = function() return 96, 32 end },
	player_jump = { getDimensions = function() return 32, 32 end },
	player_fall = { getDimensions = function() return 32, 32 end },
}
local resources = { get = function(_, _, id) return images[id] or terrain end }
local Level01 = require("game.scenes.levels.level01")
local Components = require("lua.engine.ecs.component")
local RenderSystem = require("lua.engine.ecs.systems.renderSystem")
local InputManager = require("lua.engine.input.inputManager")
local input = InputManager.new(require("game.inputMaps"))
local level = Level01.new({ resourceManager = resources, inputManager = input, viewport = {
	getViewportDimensions = function() return 400, 300 end,
} })
level:onLoad()

local world = level.world
local sprite = assert(world:getComponent(level.player, Components.Sprite))
local state = assert(world:getComponent(level.player, Components.Animation))
local idle = assert(sprite.animations.idle)
local body = assert(world:getComponent(level.player, Components.RigidBody)).body
local playerFixture = { getBody = function() return body end, isSensor = function() return false end }
local otherFixture = { getBody = function() return {} end, isSensor = function() return false end }
local function makeContact(normalY, playerFirst, touching, sensor, enabled)
	local other = { getBody = otherFixture.getBody, isSensor = function() return sensor end }
	return {
		isTouching = function() return touching end,
		isEnabled = function() return enabled end,
		getFixtures = function() if playerFirst then return playerFixture, other else return other, playerFixture end end,
		getNormal = function() return 0, normalY end,
	}
end
body.contacts = { makeContact(1, true, true, false, true) }
local spriteCount = 0
world:query({ Components.Sprite }, function() spriteCount = spriteCount + 1 end)
assert(spriteCount == 1)
assert(sprite.flipH == false)
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

state.playing = false
level:update(0.1)
assert(state.frame == 1)

state.playing = true
state.loop = false
level:update(0.31)
assert(state.frame == 3 and not state.playing)

local velocity = assert(world:getComponent(level.player, Components.Velocity))
body.velocityY = 75
input:keypressed("left")
level:update(0.1)
assert(velocity.x < 0 and body.velocityX == velocity.x and body.velocityY == 75)
assert(sprite.flipH == true)
input:keypressed("d")
level:update(0.1)
assert(velocity.x == 0 and body.velocityX == 0 and body.velocityY == 75)
assert(sprite.flipH == true)
input:keyreleased("left")
level:update(0.1)
assert(velocity.x > 0 and body.velocityX == velocity.x and body.velocityY == 75)
assert(sprite.flipH == false)
input:keyreleased("d")
level:update(0.1)
assert(velocity.x == 0 and body.velocityX == 0 and body.velocityY == 75)
assert(sprite.flipH == false)
input:keypressed("a")
level:update(0.1)
assert(velocity.x < 0 and body.velocityX == velocity.x)
assert(sprite.flipH == true)
input:keyreleased("a")
level:update(0.1)
assert(velocity.x == 0 and sprite.flipH == true)
input:keypressed("right")
level:update(0.1)
assert(velocity.x > 0 and body.velocityX == velocity.x)
assert(sprite.flipH == false)
input:keyreleased("right")
level:update(0.1)
assert(velocity.x == 0 and body.velocityX == 0)

local function tryJump(contact, verticalSpeed)
	body.contacts = contact and { contact } or {}
	body.velocityY = verticalSpeed
	input:keypressed("space")
	level:update(0.01)
	local result = body.velocityY
	input:update()
	input:keyreleased("space")
	input:update()
	return result
end
assert(tryJump(nil, 50) == 50)
assert(tryJump(makeContact(1, true, false, false, true), 0) == 0)
assert(tryJump(makeContact(1, true, true, true, true), 0) == 0)
assert(tryJump(makeContact(1, true, true, false, false), 0) == 0)
assert(tryJump(makeContact(0, true, true, false, true), 0) == 0)
assert(tryJump(makeContact(-1, true, true, false, true), 0) == 0)
assert(tryJump(makeContact(1, true, true, false, true), 0) < 0)
assert(tryJump(makeContact(1, true, true, false, true), -50) == -50)
assert(tryJump(makeContact(-1, false, true, false, true), 0) < 0)
body.contacts = { makeContact(1, true, true, false, true) }
body.velocityY = 0
input:keypressed("space")
input:keypressed("right")
level:update(0.01)
assert(body.velocityY < 0 and body.velocityX > 0)
input:update()
body.velocityY = 0
level:update(0.01)
assert(body.velocityY == 0) -- Holding the button does not trigger another jump.

input:keyreleased("space")
input:keyreleased("right")
input:update()
body.velocityY = 0
level:update(0.01)
assert(state.current == "idle" and state.frame == 1 and state.timer == 0)
assert(sprite.animations.run.image == images.player_run)
assert(sprite.animations.jump.image == images.player_jump)
assert(sprite.animations.fall.image == images.player_fall)
input:keypressed("left")
level:update(0.01)
assert(state.current == "run" and state.frame == 1 and state.timer == 0 and sprite.flipH)
level:update(0.06)
level:update(0.06)
assert(state.current == "run" and state.frame == 2)
body.velocityY = -100
level:update(0.01)
assert(state.current == "jump" and state.frame == 1 and state.timer == 0 and sprite.flipH)
body.contacts = {}
body.velocityY = 0
level:update(0.01)
assert(state.current == "fall" and state.frame == 1 and state.timer == 0)
body.velocityY = 100
level:update(0.01)
assert(state.current == "fall" and state.timer > 0)
body.contacts = { makeContact(1, true, true, false, true) }
body.velocityY = 0
level:update(0.01)
assert(state.current == "run" and state.frame == 1 and state.timer == 0)
input:keyreleased("left")
level:update(0.01)
assert(state.current == "idle" and state.frame == 1 and sprite.flipH)
print("player idle animation tests passed")
