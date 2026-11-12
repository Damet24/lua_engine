local InputManager = require("lua.engine.input.inputManager")

local inputMaps = {
	jump = { "a", "left", "gamepad_button_a" },
	run = { "space", "a" },
}
local manager = InputManager.new(inputMaps)
assert(manager.inputMaps == inputMaps)
assert(type(manager.keys.pressed) == "table")
assert(type(manager.keys.justPressed) == "table")
assert(type(manager.keys.justReleased) == "table")
assert(InputManager.new({}).inputMaps)

local function invalid(value, expected)
	local success, message = pcall(InputManager.new, value)
	assert(not success and tostring(message):find(expected, 1, true), tostring(message))
end

invalid(nil, "inputMaps must be a table")
invalid("jump", "inputMaps must be a table")
invalid({ [1] = { "a" } }, "action names")
invalid({ [""] = { "a" } }, "action names")
invalid({ jump = "a" }, "inputMaps.jump must be an array")
invalid({ jump = false }, "inputMaps.jump must be an array")
invalid({ jump = {} }, "inputMaps.jump must contain at least one binding")
invalid({ jump = { "a", "space", "a" } }, "inputMaps.jump contains duplicate binding: a")
invalid({ jump = { "a", false } }, "inputMaps.jump[2]")
invalid({ jump = { "" } }, "inputMaps.jump[1]")
invalid({ jump = { [1] = "a", [3] = "space" } }, "inputMaps.jump must not contain gaps")
invalid({ jump = { [0] = "a" } }, "positive integer indices")
invalid({ jump = { [1.5] = "a" } }, "positive integer indices")
invalid({ jump = { [math.huge] = "a" } }, "positive integer indices")
invalid({ jump = { keyboard = "a" } }, "positive integer indices")

manager:keypressed("a")
assert(manager.keys.pressed.a and manager.keys.justPressed.a)
assert(not manager.keys.justReleased.a)
manager.keys.justPressed = {}
manager:keypressed("a")
assert(manager.keys.pressed.a and not manager.keys.justPressed.a)

manager:keypressed("space")
manager:keyreleased("a")
assert(not manager.keys.pressed.a and manager.keys.justReleased.a)
assert(manager.keys.pressed.space and manager.keys.justPressed.space)
manager.keys.justReleased = {}
manager:keyreleased("a")
manager:keyreleased("unknown")
assert(not manager.keys.justReleased.a and not manager.keys.justReleased.unknown)

manager:keyreleased("space")
assert(not manager.keys.pressed.space and manager.keys.justReleased.space)
assert(manager.keys.justPressed.space) -- A press and release can occur in the same frame.
manager:keypressed("space")
assert(manager.keys.pressed.space and manager.keys.justReleased.space)

local pressed = manager.keys.pressed
local justPressed = manager.keys.justPressed
local justReleased = manager.keys.justReleased
manager:update()
assert(manager.keys.pressed == pressed and manager.keys.pressed.space)
assert(manager.keys.justPressed == justPressed and next(justPressed) == nil)
assert(manager.keys.justReleased == justReleased and next(justReleased) == nil)
manager:update()
assert(manager.keys.pressed.space and next(justPressed) == nil and next(justReleased) == nil)
manager:keyreleased("space")
assert(not manager.keys.pressed.space and manager.keys.justReleased.space)
manager:update()
assert(not manager.keys.pressed.space and next(justReleased) == nil)

print("input manager tests passed")
