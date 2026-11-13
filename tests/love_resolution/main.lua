package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

local Engine = require("engine.engine")
local engine = Engine.new({
	initialScene = "test",
	inputMaps = {},
	window = { width = 800, height = 600, fullscreen = false, resizable = true, vsync = true },
	rendering = { width = 400, height = 400, pixelPerfect = false, backgroundColor = { 0.2, 0.4, 0.6 } },
})
engine.sceneManager = {
	push = function() end,
	processPendingOperations = function() end,
	draw = function()
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.rectangle("fill", 0, 0, 200, 400)
	end,
}

function love.load()
	engine:load()
end

local captured = false
function love.draw()
	engine:draw()
	if captured then return end
	captured = true
	love.graphics.captureScreenshot(function(image)
		local success, message = pcall(function()
			local width, height = image:getDimensions()
			assert(width == 800 and height == 600)
			local red, green, blue = image:getPixel(250, 300)
			assert(red > 0.9 and green < 0.1 and blue < 0.1)
			for _, x in ipairs({ 20, 550 }) do
				red, green, blue = image:getPixel(x, 300)
				assert(math.abs(red - 0.2) < 0.02 and math.abs(green - 0.4) < 0.02 and math.abs(blue - 0.6) < 0.02)
			end
		end)
		if not success then
			io.stderr:write(tostring(message) .. "\n")
		end
		print(success and "love resolution test passed" or "love resolution test failed")
		love.event.quit(success and 0 or 1)
	end)
end