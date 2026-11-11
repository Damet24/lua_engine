
local Scene = {}
Scene.__index = Scene

function Scene.new()
    return setmetatable({
        updateBelow = false,
        drawBelow = false
    }, Scene)
end

-- Lifecycle
function Scene:onLoad() end
function Scene:onEnter() end
function Scene:onExit() end
function Scene:onDestroy() end

-- Execution
function Scene:update(dt) end
function Scene:draw() end

return Scene
