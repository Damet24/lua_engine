package.path = assert(os.getenv("ENGINE_TEST_ROOT")) .. "/?.lua;" .. package.path

rawset(love, "run", function()
	local quads = {}
	for index = 1, 1000 do quads[index] = index end
	package.loaded["lua.engine.graphics.utils"] = {
		loadQuads = function() return { image = "terrain", quads = quads } end,
	}
	love.window = { setMode = function() end }
	love.graphics = {
		newImage = function() return { getDimensions = function() return 352, 32 end } end,
		newQuad = function() return "frame" end,
		push = function() end,
		pop = function() end,
		setColor = function() end,
		draw = function() end,
		polygon = function() end,
		circle = function() end,
	}
	assert(loadfile(os.getenv("ENGINE_TEST_ROOT") .. "/main.lua"))()
	love.load()
	local world
	for index = 1, 10 do
		local name, value = debug.getupvalue(love.update, index)
		if not name then break end
		if name == "world" then world = value end
	end
	assert(world)
	local contacts = 0
	world.events:on("collision_started", function() contacts = contacts + 1 end)
	for step = 1, 120 do love.update(1 / 60) end
	love.draw()
	assert(contacts >= 2)
	local player = assert(world:getComponent(2, "Transform"))
	assert(player.x > 150 and player.x < 165)
	for entity = 2, 3 do
		local transform = assert(world:getComponent(entity, "Transform"))
		assert(math.abs(transform.y - 80) < 2)
	end
	print("main physics scene passed")
	return function() return 0 end
end)