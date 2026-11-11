local SceneManager = require("lua.engine.scene.sceneManager")

local scenes = {
	Level01 = { updateBelow = false, drawBelow = false },
	Inventory = { updateBelow = false, drawBelow = true },
	Pause = { updateBelow = false, drawBelow = true },
}

local loader = {}
function loader:load(sceneId)
	local scene = scenes[sceneId]
	scene.update = function()
		print("update: " .. sceneId)
	end
	scene.draw = function()
		print("draw: " .. sceneId)
	end
	scene.onLoad = function() end
	scene.onEnter = function() end
	return scene
end

local manager = SceneManager.new(loader)
manager:draw()
manager:push("Level01")
manager:push("Inventory")
manager:push("Pause")
assert(#manager.stack == 0)

print("--- update (top to bottom policy) ---")
manager:update(1 / 60)
assert(#manager.stack == 3)
print("--- draw (bottom to top) ---")
manager:draw()