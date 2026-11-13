local Engine = require("engine.engine")
local default = Engine.new({ initialScene = "menu", inputMaps = {} })
assert(table.concat(default.rendering.backgroundColor, ",") == "0,0,0,1")

local color = { 0.2, 0.4, 0.6 }
local engine = Engine.new({ initialScene = "menu", inputMaps = {}, rendering = { backgroundColor = color } })
assert(engine.rendering.backgroundColor ~= color and engine.rendering.backgroundColor[4] == 1)
color[1] = 0.9
local applied
love = { graphics = { setBackgroundColor = function(...) applied = { ... } end } }
package.loaded["engine.lib.shove.shove"] = { setResolution = function() end }
engine.sceneManager = { push = function() end, processPendingOperations = function() end }
engine:load()
assert(applied[1] == 0.2 and applied[2] == 0.4 and applied[3] == 0.6 and applied[4] == 1)

local alpha = Engine.new({ initialScene = "menu", inputMaps = {}, rendering = { backgroundColor = { 1, 0, 0, 0.5 } } })
assert(alpha.rendering.backgroundColor[4] == 0.5)
for _, invalid in ipairs({ false, {}, { 0, 0 }, { 0, 0, 0, 0, 0 }, { 0, -0.1, 0 }, { 0, 0, 1.1 }, { 0, 0, "1" }, { 0 / 0, 0, 0 }, { [1] = 0, [3] = 0, [4] = 0 } }) do
	local ok, message = pcall(Engine.new, { initialScene = "menu", inputMaps = {}, rendering = { backgroundColor = invalid } })
	assert(not ok and tostring(message):find("rendering.backgroundColor", 1, true))
end
print("engine background tests passed")