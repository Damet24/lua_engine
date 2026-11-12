local Scene = require("engine.scene.scene")

local MainMenu = {}
MainMenu.__index = MainMenu
setmetatable(MainMenu, { __index = Scene })

function MainMenu.new(context)
	local self = Scene.new()

	setmetatable(self, MainMenu)

	self.context = context

	return self
end

function MainMenu:onLoad()
	print("Loading MainMenu")
	self.context.resourceManager:get(self, "terrain")
end

function MainMenu:onEnter()
	print("main menu enter")
end

function MainMenu:update(dt)
	-- Actualizar el menú
	if self.context.inputManager:isJustPressed("accept") then
		self.context.sceneManager:replace("levels.level01")
	end

	-- if love.keyboard.isDown("space") then
	-- 		self.manager:pop()
	-- end
end

function MainMenu:onDestroy()
	self.context.resourceManager:releaseAll(self)
end

function MainMenu:draw()
	-- Dibujar el menú
end

return MainMenu
