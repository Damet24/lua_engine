local Engine = require("lua.engine.engine")

local calls = {}
package.loaded["lua.lib.shove.shove"] = {
	setResolution = function() end,
}
love = {
	window = {
		setMode = function(width, height, flags)
			table.insert(calls, { width = width, height = height, flags = flags })
			return true
		end,
	},
}

local function makeEngine(window)
	local engine = Engine.new({ initialScene = "menu", window = window })
	engine.sceneManager = {
		push = function(_, sceneId)
			assert(sceneId == "menu")
			table.insert(calls, "push")
		end,
		processPendingOperations = function()
			table.insert(calls, "process")
		end,
	}
	return engine
end

local engine = makeEngine({
	width = 1920, height = 1080,
	fullscreen = false, resizable = true, vsync = false,
})
engine:load()
assert(calls[1].width == 1920 and calls[1].height == 1080)
assert(calls[1].flags.fullscreen == false)
assert(calls[1].flags.resizable == true and calls[1].flags.vsync == false)
assert(calls[2] == "push" and calls[3] == "process" and engine.loaded)

calls = {}
engine = makeEngine({ width = 640, height = 480, fullscreen = true, vsync = true })
engine:load()
assert(calls[1].width == 640 and calls[1].height == 480)
assert(calls[1].flags.fullscreen == true and calls[1].flags.vsync == true)
assert(calls[1].flags.resizable == true)

calls = {}
engine = makeEngine(nil)
engine:load()
assert(calls[1] == "push" and calls[2] == "process")

calls = {}
love.window.setMode = function() return false end
engine = makeEngine({ width = 640, height = 480 })
local success, message = pcall(function() engine:load() end)
assert(not success and message:find("Failed to set window mode", 1, true))
assert(not engine.loaded and #calls == 0)

print("engine window tests passed")