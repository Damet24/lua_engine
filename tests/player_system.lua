local PlayerSystem = require("game.ecs.systems.playerSystem")
local Components = require("engine.ecs.component")

local function makePlayer()
	local body = { x = 0, y = 0, contacts = {} }
	function body:getContacts() return self.contacts end
	function body:getLinearVelocity() return self.x, self.y end
	function body:setLinearVelocity(x, y) self.x, self.y = x, y end
	local components = {
		[Components.RigidBody] = { body = body },
		[Components.Velocity] = { x = 0, y = 0 },
		[Components.Sprite] = { flipH = false },
		[Components.Animation] = { current = "idle", frame = 2, timer = 0.1 },
	}
	local playerFixture = { getBody = function() return body end, isSensor = function() return false end }
	local floorFixture = { getBody = function() return {} end, isSensor = function() return false end }
	local contact = {
		isTouching = function() return true end,
		isEnabled = function() return true end,
		getFixtures = function() return playerFixture, floorFixture end,
		getNormal = function() return 0, 1 end,
	}
	local world = { getComponent = function(_, entity, name)
		assert(entity == 7)
		return components[name]
	end }
	local input = { down = {}, pressed = {} }
	function input:isDown(action) return self.down[action] end
	function input:isJustPressed(action) return self.pressed[action] end
	return body, components, contact, world, input
end

local body, components, contact, world, input = makePlayer()
local system = PlayerSystem.new(input, 7)
body.contacts = { contact }
input.down.move_left = true
system.update(world, 0.016)
assert(body.x == -120 and components[Components.Sprite].flipH)
assert(components[Components.Animation].current == "run" and components[Components.Animation].frame == 1)
input.down.move_left = false
input.pressed.jump = true
system.update(world, 0.016)
assert(body.y == -300 and components[Components.Animation].current == "jump")
input.pressed.jump = false
system.update(world, 0.016)
assert(body.y == -300 and components[Components.Animation].current == "jump")
body.contacts = {}
body.y = 5
input.pressed.jump = true
system.update(world, 0.016)
assert(body.y == -300 and components[Components.Animation].current == "jump")
input.pressed.jump = false
system.update(world, 0.016)
body.y = 5
input.pressed.jump = true
system.update(world, 0.016)
assert(body.y == 5 and components[Components.Animation].current == "fall")
input.pressed.jump = false
body.contacts = { contact }
body.y = 0
system.update(world, 0.016)
assert(components[Components.Animation].current == "idle")
input.pressed.jump = true
system.update(world, 0.016)
assert(body.y == -300 and components[Components.Animation].current == "jump")

local otherBody, _, otherContact, otherWorld, otherInput = makePlayer()
otherBody.contacts = { otherContact }
otherInput.down.move_right = true
PlayerSystem.new(otherInput, 7).update(otherWorld, 0.016)
assert(otherBody.x == 120 and body.x == 0)
otherInput.down.move_right = false
otherBody.contacts = {}
otherBody.y = 5
otherInput.pressed.jump = true
local otherSystem = PlayerSystem.new(otherInput, 7)
otherSystem.update(otherWorld, 0.016)
assert(otherBody.y == -300)
otherBody.y = 5
otherSystem.update(otherWorld, 0.016)
assert(otherBody.y == 5)
print("player system tests passed")