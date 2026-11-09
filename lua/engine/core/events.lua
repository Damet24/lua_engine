local EventManager = {}
EventManager.__index = EventManager

function EventManager.new()
	local self = setmetatable({}, EventManager)

	self.events = {}
	self.pendingOperations = {}
	self.eventQueue = {}

	return self
end

function EventManager:on(eventName, callback)
	self.events[eventName] = self.events[eventName] or {}
	table.insert(self.events[eventName], callback)
end

function EventManager:emit(eventName, data)
	table.insert(self.eventQueue, {
		name = eventName,
		data = data,
	})
end

function EventManager:dispatch()
	local events = self.eventQueue
	self.eventQueue = {}

	for _, event in ipairs(events) do
		local listeners = self.events[event.name]

		if listeners then
			for _, callback in ipairs(listeners) do
				callback(event.data)
			end
		end
	end

	self:flush()
end

function EventManager:off(eventName, callback)
	table.insert(self.pendingOperations, {
		type = "remove",
		eventName = eventName,
		callback = callback,
	})
end

function EventManager:flush()
	local operations = self.pendingOperations
	self.pendingOperations = {}

	for _, operation in ipairs(operations) do
		local event = self.events[operation.eventName]

		if operation.type == "remove" and event then
			for index, registeredCallback in ipairs(event) do
				if registeredCallback == operation.callback then
					table.remove(event, index)
					break
				end
			end
		end
	end
end

return EventManager
