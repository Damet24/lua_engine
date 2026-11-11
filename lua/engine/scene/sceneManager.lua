local SceneManager = {}
SceneManager.__index = SceneManager

local function merge(t1, t2)
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    if t2 then
        for k, v in pairs(t2) do result[k] = v end
    end
    return result
end

function SceneManager.new(sceneLoader)
	assert(sceneLoader, "sceneLoader is required")

	local self = setmetatable({}, SceneManager)

	self.sceneLoader = sceneLoader
	self.stack = {}
	self.pendingOperations = {}

	return self
end

function SceneManager:push(sceneId, dependencies)
    table.insert(self.pendingOperations, {
        type = "push",
        sceneId = sceneId,
        dependencies = merge({ manager = self }, dependencies),
    })
end

function SceneManager:processPendingOperations()
    local pendingOperations = self.pendingOperations
    self.pendingOperations = {}

    for _, operation in ipairs(pendingOperations) do
        if operation.type == "push" then
            self:applyPush(
                operation.sceneId,
                operation.dependencies
            )
		elseif operation.type == "pop" then
			self:applyPop()
		elseif operation.type == "replace" then
			self:applyReplace(
				operation.sceneId,
				operation.dependencies
			)
		elseif operation.type == "clearAndPush" then
			self:applyClearAndPush(
				operation.sceneId,
				operation.dependencies
			)
		end
    end
end

function SceneManager:applyPush(sceneId, dependencies)
    local scene = self.sceneLoader:load(sceneId, dependencies)

    scene:onLoad()

    local current = self.stack[#self.stack]
    if current then
        current.scene:onExit()
    end

    table.insert(self.stack, {
        id = sceneId,
        scene = scene,
    })

    scene:onEnter()
end

function SceneManager:pop()
    table.insert(self.pendingOperations, {
        type = "pop",
    })
end

function SceneManager:applyPop()
    local current = self.stack[#self.stack]
    if not current then return end

    current.scene:onExit()
    table.remove(self.stack)
    current.scene:onDestroy()

    local previous = self.stack[#self.stack]
    if previous then
        previous.scene:onEnter()
    end
end

function SceneManager:replace(sceneId, dependencies)
	table.insert(self.pendingOperations, {
        type = "replace",
        sceneId = sceneId,
        dependencies = merge({ manager = self }, dependencies),
    })
end

function SceneManager:applyReplace(sceneId, dependencies)
    local newScene = self.sceneLoader:load(sceneId, dependencies)
    newScene:onLoad()

    local current = self.stack[#self.stack]
    if current then
        current.scene:onExit()
        table.remove(self.stack)
        current.scene:onDestroy()
    end

    table.insert(self.stack, { id = sceneId, scene = newScene })
    newScene:onEnter()
end

function SceneManager:applyClearAndPush(sceneId, dependencies)
	local newScene = self.sceneLoader:load(sceneId, dependencies)
	newScene:onLoad()

	for i = #self.stack, 1, -1 do
		self.stack[i].scene:onExit()
	end

	for i = #self.stack, 1, -1 do
		self.stack[i].scene:onDestroy()
	end

	self.stack = {
		{
			id = sceneId,
			scene = newScene,
		},
	}

	newScene:onEnter()
end

function SceneManager:clearAndPush(sceneId, dependencies)
	table.insert(self.pendingOperations, {
        type = "clearAndPush",
        sceneId = sceneId,
        dependencies = merge({ manager = self }, dependencies),
    })
end


function SceneManager:update(dt)
	local firstScene = math.max(1, #self.stack)

    -- Determine the lowest scene that should be updated
    for i = #self.stack, 1, -1 do
        firstScene = i

        if not self.stack[i].scene.updateBelow then
            break
        end
    end

    -- Update scenes from bottom to top
    for i = firstScene, #self.stack do
        self.stack[i].scene:update(dt)
    end

	self:processPendingOperations()
end


function SceneManager:draw()
	local firstScene = math.max(1, #self.stack)

    -- Determine the lowest scene that should be drawn
    for i = #self.stack, 1, -1 do
        firstScene = i

        if not self.stack[i].scene.drawBelow then
            break
        end
    end

    -- Draw scenes from bottom to top
    for i = firstScene, #self.stack do
        self.stack[i].scene:draw()
    end
end

return SceneManager
