local EventManager = require("lua.engine.core.events")

local World = {}
World.__index = World

function World.new()
	local self = setmetatable({}, World)

	self.nextEntityId = 0
	self.entities = {}
	self.components = {}
	self.systems = {}

	self.events = EventManager.new()

	return self
end

function World:createEntity()
	self.nextEntityId = self.nextEntityId + 1
	local entity = self.nextEntityId
	self.entities[entity] = true
	return entity
end

function World:destroyEntity(entity)
	if not self.entities[entity] then
		return
	end

	self.pendingDestroy[entity] = true
end

function World:flushDestroy()
	for entity in pairs(self.pendingDestroy) do
		self.entities[entity] = nil

		for _, storage in pairs(self.components) do
			storage[entity] = nil
		end
	end

	self.pendingDestroy = {}
end

-- COMPONENT MANAGMENT

function World:addComponent(entity, name, data)
	assert(self.entities[entity], "Invalid entity")
	self.components[name] = self.components[name] or {}
	self.components[name][entity] = data or {}
end

function World:getComponent(entity, name)
	local storage = self.components[name]

	if not storage then
		return nil
	end

	return storage[entity]
end

function World:hasComponent(entity, name)
	return self:getComponent(entity, name) ~= nil
end

function World:removeComponent(entity, name)
	local storage = self.components[name]

	if storage then
		storage[entity] = nil
	end
end

-- ENTITY QUERY

function World:query(componentNames, callback)
	for entity in pairs(self.entities) do
		local components = {}
		local matches = true

		for _, name in ipairs(componentNames) do
			local component = self:getComponent(entity, name)

			if not component then
				matches = false
				break
			end

			components[name] = component
		end

		if matches then
			callback(entity, components)
		end
	end
end

-- SYSTEM MANAGEMENT

function World:addSystem(system)
	table.insert(self.systems, system)
end

function World:update(dt)
	for _, system in ipairs(self.systems) do
		system.update(self, dt)
	end

	self.events:dispatch()

	self:flushDestroy()
end

return World
