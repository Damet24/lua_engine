local SceneManager = require("lua.engine.scene.sceneManager")

local events = {}
local manager
local dependencies = { marker = "injected" }
local loader = {}

function loader:load(sceneId, passedDependencies)
	assert(passedDependencies.manager == manager)
	assert(passedDependencies.marker == dependencies.marker)
	table.insert(events, sceneId .. ":load")
	if sceneId == "loadFailure" then
		error("load failed")
	end

	local scene = {}
	for _, callback in ipairs({ "onLoad", "onEnter", "onExit", "onDestroy" }) do
		scene[callback] = function()
			table.insert(events, sceneId .. ":" .. callback)
			if sceneId == "onLoadFailure" and callback == "onLoad" then
				error("onLoad failed")
			end
		end
	end
	scene.update = function() end
	return scene
end

manager = SceneManager.new(loader)
manager:push("lower", dependencies)
manager:push("old", dependencies)
manager:update(0)
local lower = manager.stack[1]
local old = manager.stack[2]

for _, failure in ipairs({ "loadFailure", "onLoadFailure" }) do
	events = {}
	manager:replace(failure, dependencies)
	assert(manager.stack[2] == old and #events == 0)
	local success, message = pcall(function() manager:update(0) end)
	assert(not success and type(message) == "string" and message:find("failed", 1, true))
	assert(#manager.stack == 2 and manager.stack[1] == lower and manager.stack[2] == old)
	assert(table.concat(events, ",") == (failure == "loadFailure" and "loadFailure:load" or "onLoadFailure:load,onLoadFailure:onLoad"))
end

events = {}
old.scene.update = function()
	table.insert(events, "old:update")
	manager:replace("new", dependencies)
	assert(manager.stack[2] == old)
end
manager:update(0)
assert(#manager.stack == 2 and manager.stack[1] == lower and manager.stack[2].id == "new")
assert(table.concat(events, ",") == "old:update,new:load,new:onLoad,old:onExit,old:onDestroy,new:onEnter")

events = {}
manager = SceneManager.new(loader)
manager:replace("first", dependencies)
assert(#manager.stack == 0 and #events == 0)
manager:update(0)
assert(#manager.stack == 1 and manager.stack[1].id == "first")
assert(table.concat(events, ",") == "first:load,first:onLoad,first:onEnter")

print("scene replace tests passed")