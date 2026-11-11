local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new(definitions, loaders)
    local self = setmetatable({}, ResourceManager)

    self.definitions = definitions
    self.loaders = loaders
    self.resources = {}

    return self
end

function ResourceManager:get(consumer, resourceId)
    local resource = self.resources[resourceId]
    if not resource then
        local definition = assert(
            self.definitions[resourceId],
            ("Resource '%s' is not defined"):format(resourceId)
        )

        local loader = assert(
            self.loaders[definition.type],
            ("No loader registered for resource type '%s'"):format(definition.type)
        )

        resource = {
            resource = loader.load(definition),
            release = loader.release,
            consumers = {},
        }
        self.resources[resourceId] = resource
    end
    resource.consumers[consumer] = true
    return resource.resource
end

function ResourceManager:release(consumer, resourceId)
    local resource = self.resources[resourceId]
    if not resource then return end

    if not resource.consumers[consumer] then return end

    resource.consumers[consumer] = nil

    if next(resource.consumers) == nil then
        self:releaseResource(resourceId)
    end
end

function ResourceManager:releaseResource(resourceId)
    local resource = self.resources[resourceId]
    if not resource then return end

    resource.release(resource.resource)
    self.resources[resourceId] = nil
end

function ResourceManager:releaseAll(consumer)
    for resourceId, resource in pairs(self.resources) do
        if resource.consumers[consumer] then
            self:release(consumer, resourceId)
        end
    end
end

return ResourceManager
