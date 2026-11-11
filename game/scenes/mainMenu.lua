local Scene = require("lua.engine.scene.scene")

local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, { __index = Scene })

function MainMenu.new(dependencies)
	local self = Scene.new()

	setmetatable(self, MainMenu)

	self.manager = dependencies.manager

	return self
end

function MainMenu:onLoad()
	print("Loading MainMenu")
end

function MainMenu:onEnter()
	print("main menu enter")
end

function MainMenu:update(dt)
	-- Actualizar el menú
	if love.keyboard.isDown("return") then
			self.manager:replace("levels.level01")
	end

	-- if love.keyboard.isDown("space") then
	-- 		self.manager:pop()
	-- end
end

function MainMenu:draw()
	-- Dibujar el menú
end

return MainMenu
