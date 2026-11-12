local SceneManager = require("lua.engine.scene.sceneManager")

local events = {}
local manager
local loader = {}

function loader:load(sceneId)
	local scene = {}
	for _, callback in ipairs({ "onLoad", "onEnter", "onExit", "onDestroy" }) do
		scene[callback] = function()
			table.insert(events, sceneId .. ":" .. callback)
		end
	end
	scene.update = function() end
	return scene
end

manager = SceneManager.new(loader)
manager:clear()
manager:update(0)
assert(#manager.stack == 0 and #events == 0)

manager:push("lower")
manager:push("middle")
manager:push("upper")
manager:update(0)
events = {}

manager.stack[3].scene.update = function()
	table.insert(events, "upper:update")
	manager:clear()
	assert(#manager.stack == 3)
end
manager:update(0)
assert(#manager.stack == 0)
assert(table.concat(events, ",") == table.concat({
	"upper:update", "upper:onExit",
	"upper:onDestroy", "middle:onDestroy", "lower:onDestroy",
}, ","))

events = {}
manager:clear()
manager:update(0)
assert(#manager.stack == 0 and #events == 0)

manager:push("old")
manager:update(0)
events = {}
manager.stack[1].scene.onExit = function()
	assert(#manager.stack == 0)
	table.insert(events, "old:onExit")
end
manager.stack[1].scene.onDestroy = function()
	assert(#manager.stack == 0)
	table.insert(events, "old:onDestroy")
	manager:push("new")
end
manager:clear()
manager:update(0)
assert(#manager.stack == 0)
assert(table.concat(events, ",") == "old:onExit,old:onDestroy")
manager:update(0)
assert(#manager.stack == 1 and manager.stack[1].id == "new")
assert(table.concat(events, ",") == "old:onExit,old:onDestroy,new:onLoad,new:onEnter")

print("scene clear tests passed")