local SceneManager = require("engine.scene.sceneManager")

local events = {}
local dependencies = { marker = "injected" }

local function makeScene(sceneId)
	local scene = {}
	scene.update = function() end
	scene.draw = function() end
	for _, callback in ipairs({ "onLoad", "onEnter", "onExit", "onDestroy" }) do
		scene[callback] = function()
			table.insert(events, sceneId .. ":" .. callback)
		end
	end
	return scene
end

local loader = {}
function loader:load(sceneId, passedDependencies)
	assert(passedDependencies == dependencies)
	return makeScene(sceneId)
end

local manager = SceneManager.new(loader)
manager:push("first", dependencies)
manager:push("second", dependencies)
assert(#manager.stack == 0 and #events == 0)
manager:update(0)
assert(#manager.stack == 2 and manager.stack[1].id == "first" and manager.stack[2].id == "second")
manager:pop()
assert(#manager.stack == 1 and manager.stack[1].id == "first")
manager:pop()
manager:pop()
assert(#manager.stack == 0)
assert(table.concat(events, ",") == table.concat({
	"first:onLoad", "first:onEnter",
	"second:onLoad", "second:onEnter",
	"second:onExit", "second:onDestroy", "first:onEnter",
	"first:onExit", "first:onDestroy",
}, ","))

events = {}
manager:push("old", dependencies)
manager:update(0)
manager:replace("replacement", dependencies)
assert(#manager.stack == 1 and manager.stack[1].id == "replacement")
assert(table.concat(events, ",") == table.concat({
	"old:onLoad", "old:onEnter",
	"replacement:onLoad", "old:onExit", "old:onDestroy", "replacement:onEnter",
}, ","))

events = {}
manager = SceneManager.new(loader)
manager:push("lower", dependencies)
manager:push("upper", dependencies)
manager:update(0)
manager:clearAndPush("fresh", dependencies)
assert(#manager.stack == 1 and manager.stack[1].id == "fresh")
assert(table.concat(events, ",") == table.concat({
	"lower:onLoad", "lower:onEnter",
	"upper:onLoad", "upper:onEnter",
	"fresh:onLoad",
	"upper:onExit", "lower:onExit",
	"upper:onDestroy", "lower:onDestroy",
	"fresh:onEnter",
}, ","))

events = {}
manager = SceneManager.new(loader)
manager:push("lower", dependencies)
manager:push("upper", dependencies)
manager:update(0)
events = {}
manager.stack[2].scene.updateBelow = true
manager.stack[1].scene.update = function()
	table.insert(events, "lower:update")
	manager:push("duringUpdate", dependencies)
	assert(#manager.stack == 2)
end
manager.stack[2].scene.update = function()
	table.insert(events, "upper:update")
	assert(#manager.stack == 2)
end
manager:update(0)
assert(table.concat(events, ",") == "lower:update,upper:update,duringUpdate:onLoad,duringUpdate:onEnter")
assert(#manager.stack == 3 and manager.stack[3].id == "duringUpdate")

events = {}
manager.stack[3].scene.draw = function()
	table.insert(events, "draw")
	manager:push("duringDraw", dependencies)
	assert(#manager.stack == 3)
end
manager:draw()
assert(table.concat(events, ",") == "draw,duringDraw:onLoad,duringDraw:onEnter")
assert(#manager.stack == 4 and manager.stack[4].id == "duringDraw")

events = {}
local callbackLoader = {}
function callbackLoader:load(sceneId, passedDependencies)
	local scene = loader:load(sceneId, passedDependencies)
	if sceneId == "parent" then
		scene.onEnter = function()
			table.insert(events, "parent:onEnter")
			manager:push("child", dependencies)
		end
	end
	return scene
end
manager = SceneManager.new(callbackLoader)
manager:push("parent", dependencies)
manager:draw()
assert(#manager.stack == 1 and manager.stack[1].id == "parent")
assert(table.concat(events, ",") == "parent:onLoad,parent:onEnter")
manager:update(0)
assert(#manager.stack == 2 and manager.stack[2].id == "child")
assert(table.concat(events, ",") == "parent:onLoad,parent:onEnter,child:onLoad,child:onEnter")

print("scene manager tests passed")