local GameContext = {}
GameContext.__index = GameContext

function GameContext.new(services)
    assert(services, "services are required")

    return setmetatable({
        resourceManager = assert(
            services.resourceManager,
            "resourceManager is required"
        ),
        audioManager = assert(
            services.audioManager,
            "audioManager is required"
        ),
        sceneManager = services.sceneManager,
    }, GameContext)
end

return GameContext
