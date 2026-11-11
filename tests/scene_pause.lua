local SceneManager = require("lua.engine.scene.sceneManager")
local Level01 = require("game.scenes.levels.level01")
local Pause = require("game.scenes.pause")

local escapeDown = false
local updates = 0
local drawCalls = {}
local font = { getHeight = function() return 36 end }
love = {
	keyboard = { isDown = function(key) assert(key == "escape" or key == "space"); return key == "escape" and escapeDown end },
	graphics = {
		newFont = function(size) assert(size == 36); return font end,
		getDimensions = function() return 1280, 720 end,
		push = function() end,
		pop = function() end,
		setColor = function() end,
		rectangle = function() end,
		setFont = function(selected) assert(selected == font) end,
		printf = function(...) drawCalls = { ... } end,
	},
}

local loader = {}
function loader:load(sceneId, dependencies)
	local context = {
		sceneManager = dependencies.manager,
		resourceManager = {
			get = function(_, _, resourceId) assert(resourceId == "pause_font"); return font end,
			releaseAll = function() end,
		},
	}
	if sceneId == "pause" then
		return Pause.new(context)
	end
	assert(sceneId == "level")
	local scene = Level01.new(context)
	scene.player = 1
	scene.world = {
		getComponent = function(_, _, component)
			if component == "RigidBody" then
				return { body = { getLinearVelocity = function() return 0, 0 end, setLinearVelocity = function() end } }
			end
			return { x = 0 }
		end,
		update = function() updates = updates + 1 end,
	}
	return setmetatable({ onLoad = function() end, draw = function() end }, { __index = scene })
end

local manager = SceneManager.new(loader)
manager:push("level")
manager:update(0)
escapeDown = true
manager:update(0)
assert(#manager.stack == 2 and manager.stack[2].id == "pause")
assert(updates == 1)
manager:draw()
assert(drawCalls[1] == "PAUSA" and drawCalls[2] == 0 and drawCalls[3] == 342 and drawCalls[4] == 1280 and drawCalls[5] == "center")
manager:update(0)
assert(#manager.stack == 2 and updates == 1)
escapeDown = false
manager:update(0)
escapeDown = true
manager:update(0)
assert(#manager.stack == 1 and manager.stack[1].id == "level" and updates == 1)
manager:update(0)
assert(#manager.stack == 1 and updates == 2)
escapeDown = false
manager:update(0)
escapeDown = true
manager:update(0)
assert(#manager.stack == 2 and manager.stack[2].id == "pause")

print("scene pause tests passed")