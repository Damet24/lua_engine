local Scene = require("lua.engine.scene.scene")

local Pause = {}
Pause.__index = Pause

setmetatable(Pause, {
	__index = Scene,
})

function Pause.new(dependencies)
	local self = Scene.new()
	setmetatable(self, Pause)
	self.manager = dependencies.manager
	self.drawBelow = true
	self.escapeDown = true
	return self
end

function Pause:onLoad()
	self.font = love.graphics.newFont(36)
end

function Pause:update(dt)
	local escapeDown = love.keyboard.isDown("escape")
	if escapeDown and not self.escapeDown then
		self.manager:pop()
	end
	self.escapeDown = escapeDown
end

function Pause:draw()
	local width, height = love.graphics.getDimensions()
	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, width, height)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(self.font)
	love.graphics.printf("PAUSA", 0, (height - self.font:getHeight()) / 2, width, "center")
	love.graphics.pop()
end

return Pause