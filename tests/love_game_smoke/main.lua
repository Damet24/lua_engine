local root = assert(os.getenv("ENGINE_TEST_ROOT"))
package.path = root .. "/?.lua;" .. package.path

rawset(love, "load", function()
	local ok, message = xpcall(function()
		local originalNewImage = love.graphics.newImage
		rawset(love.graphics, "newImage", function(path)
			local file = assert(io.open(root .. "/" .. path, "rb"))
			local data = file:read("*a")
			file:close()
			return originalNewImage(love.filesystem.newFileData(data, path))
		end)
		assert(loadfile(root .. "/main.lua"))()
		love.load()
		local _, engine = debug.getupvalue(love.update, 1)
		assert(engine and engine.sceneManager.stack[1].id == "mainMenu")
		love.keypressed("return")
		love.update(1 / 60)
		love.keyreleased("return")
		assert(engine.sceneManager.stack[1].id == "levels.level01")
		love.update(1 / 60)
		local draw = love.draw
		rawset(love, "draw", function()
			local drawn, errorMessage = xpcall(draw, debug.traceback)
			if not drawn then io.stderr:write(errorMessage .. "\n") end
			engine:quit()
			if drawn then print("LÖVE game smoke test passed") end
			love.event.quit(drawn and 0 or 1)
		end)
	end, debug.traceback)
	if not ok then
		io.stderr:write(message .. "\n")
		love.event.quit(1)
	end
end)