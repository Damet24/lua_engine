package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

local Scene = require("lua.engine.scene.scene")
local SceneManager = require("lua.engine.scene.sceneManager")
local CameraManager = require("lua.engine.camera.cameraManager")
local RenderPipeline = require("lua.engine.graphics.render_pipeline")
local viewport = require("lua.lib.shove.shove")

local TestScene = {}
TestScene.__index = TestScene
setmetatable(TestScene, { __index = Scene })

function TestScene.new(x)
	local self = setmetatable(Scene.new(), TestScene)
	self.x = x
	return self
end

function TestScene:onLoad()
	self.cameraManager = CameraManager.new()
	self.cameraManager:add("gameplay", { x = self.x, y = 200, viewport = { width = 400, height = 400 } })
	self.cameraManager:add("minimap", { viewport = { x = 300, y = 20, width = 80, height = 80, clip = true } })
	self.cameraManager:setActive("gameplay")
end

function TestScene:onDestroy()
	self.cameraManager = nil
end

function TestScene:draw()
	local pipeline = RenderPipeline.new()
	pipeline:add(1, function()
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("fill", 140, 190, 20, 20)
	end)
	self.cameraManager:getActive():draw(function() pipeline:draw() end)
	self.cameraManager:get("minimap"):draw(function()
		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.rectangle("fill", -100, -100, 200, 200)
	end)
	love.graphics.setColor(0, 0, 1, 1)
	love.graphics.rectangle("fill", 10, 10, 20, 20)
end

local scene
rawset(love, "load", function()
	viewport.setResolution(400, 400, { fitMethod = "aspect" })
	local loader = { load = function(_, id) return TestScene.new(id == "first" and 150 or 250) end }
	local manager = SceneManager.new(loader)
	manager:push("first")
	manager:processPendingOperations()
	scene = manager.stack[1].scene
	local first = scene.cameraManager:getActive()
	manager:push("second")
	manager:processPendingOperations()
	local secondScene = manager.stack[2].scene
	local second = secondScene.cameraManager:getActive()
	assert(first ~= second and scene.cameraManager ~= secondScene.cameraManager)
	second:setPosition(300, 200)
	local x = first:getPosition()
	assert(x == 150)
	manager:pop()
	manager:processPendingOperations()
	assert(secondScene.cameraManager == nil and manager.stack[1].scene == scene)
	assert(scene.cameraManager:getActive() == first)
end)

local captured = false
rawset(love, "draw", function()
	if captured then return end
	captured = true
	local ok, message = xpcall(function()
		viewport.beginDraw()
		local depth = love.graphics.getStackDepth()
		local beforeX, beforeY = love.graphics.transformPoint(0, 0)
		local sx, sy, sw, sh = love.graphics.getScissor()
		local camera = scene.cameraManager:getActive()
		local failed = pcall(function() camera:draw(function()
			love.graphics.push("all")
			love.graphics.translate(99, 99)
			error("nested renderer error")
		end) end)
		assert(not failed and love.graphics.getStackDepth() == depth)
		local afterX, afterY = love.graphics.transformPoint(0, 0)
		local ax, ay, aw, ah = love.graphics.getScissor()
		assert(beforeX == afterX and beforeY == afterY and sx == ax and sy == ay and sw == aw and sh == ah)
		local logicalX, logicalY = camera:cameraCoords(150, 200)
		assert(logicalX == 200 and logicalY == 200)
		local inside, viewportX, viewportY = viewport.screenToViewport(400, 300)
		local worldX, worldY = camera:worldCoords(viewportX, viewportY)
		assert(inside and math.abs(worldX - 150) < 0.001 and math.abs(worldY - 200) < 0.001)
		scene:draw()
		viewport.endDraw()
	end, debug.traceback)
	if not ok then
		io.stderr:write(message .. "\n")
		love.event.quit(1)
		return
	end
	love.graphics.captureScreenshot(function(image)
		local success, errorMessage = pcall(function()
			local function check(x, y, expectedR, expectedG, expectedB)
				local red, green, blue = image:getPixel(x, y)
				assert(math.abs(red - expectedR) < 0.1 and math.abs(green - expectedG) < 0.1 and math.abs(blue - expectedB) < 0.1, "unexpected pixel at " .. x .. "," .. y)
			end
			check(400, 300, 1, 0, 0)
			check(130, 30, 0, 0, 1)
			check(600, 60, 0, 1, 0)
			check(540, 60, 0, 0, 0)
			check(680, 60, 0, 0, 0)
		end)
		if not success then io.stderr:write(tostring(errorMessage) .. "\n") end
		print(success and "love camera integration tests passed" or "love camera integration tests failed")
		love.event.quit(success and 0 or 1)
	end)
end)