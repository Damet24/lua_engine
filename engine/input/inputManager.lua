local InputManager = {}
InputManager.__index = InputManager

function InputManager.new(inputMaps)
	assert(type(inputMaps) == "table", "inputMaps must be a table")
	for action, bindings in pairs(inputMaps) do
		assert(type(action) == "string" and #action > 0, "inputMaps action names must be non-empty strings")
		assert(type(bindings) == "table", "inputMaps." .. action .. " must be an array of bindings")

		local count, maxIndex = 0, 0
		local seen = {}
		for index, binding in pairs(bindings) do
			assert(
				type(index) == "number" and index > 0 and index < math.huge and index == math.floor(index),
				"inputMaps." .. action .. " must be an array with positive integer indices"
			)
			assert(
				type(binding) == "string" and #binding > 0,
				"inputMaps." .. action .. "[" .. index .. "] must be a non-empty string"
			)
			assert(not seen[binding], "inputMaps." .. action .. " contains duplicate binding: " .. binding)
			seen[binding] = true
			count = count + 1
			maxIndex = math.max(maxIndex, index)
		end
		assert(count > 0, "inputMaps." .. action .. " must contain at least one binding")
		assert(count == maxIndex, "inputMaps." .. action .. " must not contain gaps")
	end

	local self = setmetatable({}, InputManager)

	self.inputMaps = inputMaps

	self.keys = {
		pressed = {},
		justPressed = {},
		justReleased = {},
	}

	return self
end

function InputManager:keypressed(key)
	print(key)
	if not self.keys.pressed[key] then
		self.keys.pressed[key] = true
		self.keys.justPressed[key] = true
	end
end

function InputManager:keyreleased(key)
	print(key)
	if self.keys.pressed[key] then
		self.keys.pressed[key] = nil
		self.keys.justReleased[key] = true
	end
end

function InputManager:update()
	self.keys.justPressed = {}
	self.keys.justReleased = {}
end

function InputManager:isDown(action)
	local bindings = self.inputMaps[action]

	if not bindings then
		return false
	end

	for _, key in ipairs(bindings) do
		if self.keys.pressed[key] then
			return true
		end
	end

	return false
end

function InputManager:isJustPressed(action)
	local bindings = self.inputMaps[action]

	if not bindings then
		return false
	end
	for _, key in ipairs(bindings) do
		if self.keys.justPressed[key] then
			return true
		end
	end

	return false
end

function InputManager:isJustReleased(action)
	local bindings = self.inputMaps[action]

	if not bindings then
		return false
	end
	for _, key in ipairs(bindings) do
		if self.keys.justReleased[key] then
			return true
		end
	end

	return false
end

return InputManager
