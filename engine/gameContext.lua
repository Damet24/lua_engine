local GameContext = {}
GameContext.__index = GameContext

function GameContext.new(config)
	local self = setmetatable({}, GameContext)
	self.resourceManager = assert(config.resourceManager, "resourceManager is required")
	return self
end

return GameContext
